#! /bin/bash

setenforce 0
grubby --update-kernel ALL --args selinux=0

until dnf install -y wget httpd php php-gd php-mysqlnd php-curl php-opcache mod_ssl; do
    echo "dnf is locked by another process. Waiting 5 seconds..."
    sleep 5
done

wget https://ko.wordpress.org/wordpress-7.0-ko_KR.tar.gz
tar zxvf wordpress-7.0-ko_KR.tar.gz
cp -ar ./wordpress/* /var/www/html/

while [ ! -f /var/www/html/wp-config-sample.php ]; do
    sleep 2
done
cp /var/
www/html/wp-config-sample.php /var/www/html/wp-config.php
sed -i "s/DirectoryIndex index.html/DirectoryIndex index.php/g" /etc/httpd/conf/httpd.conf

TOKEN=$(curl -s "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net&client_id=${uami_client_id}" -H Metadata:true | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)
DB_PSWD=$(curl -s -H "Authorization: Bearer $TOKEN" "https://${kv_name}.vault.azure.net/secrets/db-pswd?api-version=7.0" | grep -o '"value":"[^"]*' | cut -d'"' -f4)

sed -i 's/\r//g' /var/www/html/wp-config.php
sed -i "s|database_name_here|wordpress|g" /var/www/html/wp-config.php
sed -i "s|username_here|team61|g" /var/www/html/wp-config.php
sed -i "s|localhost|${db_host}|g" /var/www/html/wp-config.php
sed -i "s#password_here#$DB_PSWD#g" /var/www/html/wp-config.php
sed -i "/That's all, stop editing/i define( 'MYSQL_CLIENT_FLAGS', MYSQLI_CLIENT_SSL );" /var/www/html/wp-config.php

chmod 400 /var/www/html/wp-config.php
chown -R apache:apache /var/www/html/

cat << 'EOF' > /var/www/html/api.php
<?php
$host     = '${db_host}';
$db       = 'wordpress';
$user     = 'team61';
$password = '$db_pswd';
$charset  = 'utf8mb4';

$dsn = "mysql:host=$host;dbname=$db;charset=$charset";
$options = [
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_EMULATE_PREPARES   => false,
];

try {
    $pdo = new PDO($dsn, $user, $password, $options);

    // 테이블 자동 생성 로직
    $createTableSql = "CREATE TABLE IF NOT EXISTS schedules (
        id INT AUTO_INCREMENT PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        ev_date DATE NOT NULL,
        ev_time TIME NULL,
        category VARCHAR(50) NULL,
        memo TEXT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB;";
    $pdo->exec($createTableSql);

    // 백엔드 API 라우터
    if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_GET['api']) && $_GET['api'] === 'add_event') {
        $input = json_decode(file_get_contents('php://input'), true);
        
        if (!empty($input['title'])) {
            $ev_date = !empty($input['date']) ? $input['date'] : date('Y-m-d');
            $ev_time = !empty($input['time']) ? $input['time'] : null;
            $category = !empty($input['category']) ? $input['category'] : '기타';
            $memo = !empty($input['memo']) ? $input['memo'] : null;

            $stmt = $pdo->prepare("INSERT INTO schedules (title, ev_date, ev_time, category, memo) VALUES (?, ?, ?, ?, ?)");
            $stmt->execute([$input['title'], $ev_date, $ev_time, $category, $memo]);
            
            header('Content-Type: application/json');
            echo json_encode(['status' => 'success']);
            exit;
        }
    }

    if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_GET['api']) && $_GET['api'] === 'delete_event') {
        header('Content-Type: application/json');
        $input = json_decode(file_get_contents('php://input'), true);
        
        if (!empty($input['title'])) {
            $stmt = $pdo->prepare("DELETE FROM schedules WHERE title = ? AND ev_date = ?");
            $stmt->execute([$input['title'], $input['date']]);
            
            echo json_encode(['status' => 'success']);
            exit;
        }
    }

} catch (\PDOException $e) {
    $dbError = $e->getMessage();
}
?>
<?php if (isset($dbError)): ?>
    <div style="color:red; background:white; padding:20px;">DB 연결 실패: <?php echo $dbError; ?></div>
<?php endif; ?>
EOF

# 5. 🛡️ 제로 트러스트 설정 (80번 포트 닫기)
sed -i 's/^Listen 80/#Listen 80/' /etc/httpd/conf/httpd.conf

# 6. 🚨 [자동화의 핵심] 인증서 무한 대기 (타임아웃 없음)
# Azure가 waagent 폴더에 인증서를 뱉어낼 때까지 다음 단계로 넘어가지 않습니다.
until ls /var/lib/waagent/*.prv >/dev/null 2>&1 && ls /var/lib/waagent/*.crt >/dev/null 2>&1; do
    echo "Waiting for Key Vault certificates delivery..."
    sleep 5
done

# 여러 인증서 중 'Azure 내부용(CRP)'이 아닌 진짜 Key Vault 인증서만 찾아내기!
for cert in /var/lib/waagent/*.crt; do
    # 인증서 주체(subject)를 까서 "CRP"라는 단어가 없으면 진짜로 판정!
    if ! openssl x509 -in "$cert" -noout -subject | grep -q "Windows Azure CRP"; then
        CRT_FILE="$cert"
        # .crt 확장자를 .prv로 바꿔서 짝꿍 개인키 파일 이름 맞추기
        PRV_FILE="$${cert%.crt}.prv"
        break
    fi
done

cp "$CRT_FILE" /etc/pki/tls/certs/team61_kv.crt
cp "$PRV_FILE" /etc/pki/tls/certs/team61_kv.key

# 🛡️ 완벽한 보안: 개인키(.key)는 최고 관리자만 읽을 수 있도록 철저히 권한 통제
chmod 600 /etc/pki/tls/certs/team61_kv.key

# 기존의 쓸데없는 깡통 SSL 설정 파일 제거
rm -f /etc/httpd/conf.d/ssl.conf

# 완벽한 443 포트 설정 주입 (공개 인증서와 개인키를 각각 제자리에 맵핑)
cat << 'EOF_SSL' > /etc/httpd/conf.d/team61-ssl.conf
Listen 443 https
<VirtualHost *:443>
    SSLEngine on
    SSLCertificateFile /etc/pki/tls/certs/team61_kv.crt
    SSLCertificateKeyFile /etc/pki/tls/certs/team61_kv.key
    DocumentRoot "/var/www/html"
</VirtualHost>
EOF_SSL

# 7. 웹 서버 구동
systemctl enable --now httpd