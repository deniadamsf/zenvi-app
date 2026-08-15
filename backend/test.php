<?php
try {
    $db = new PDO('mysql:host=127.0.0.1;dbname=zenvi', 'root', '', [
        PDO::ATTR_TIMEOUT => 2,
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION
    ]);
    echo "Connected successfully to PDO\n";
    $result = $db->query("SHOW TABLES")->fetchAll();
    echo "Tables: " . count($result) . "\n";
} catch (PDOException $e) {
    echo "Connection failed: " . $e->getMessage() . "\n";
}
