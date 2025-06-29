<?php
$hashedPassword = '$2a$12$vVtdm7WLBlv3Es9nW3lvhucY3mexAnu2N9pCJyF/6Ngb6GsHqSXVy';
$inputPassword = 'admin123';

echo "Password inserita: " . $inputPassword . "<br>";
echo "Hash nel database: " . $hashedPassword . "<br>";

if (password_verify($inputPassword, $hashedPassword)) {
    echo "✅ La password è corretta!";
} else {
    echo "❌ Password errata!";
}
?>
