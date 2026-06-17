<?php
require_once "config.php";

$mensaje = "";
$tipo = "";

if ($_SERVER["REQUEST_METHOD"] === "POST") {
    $usuario = trim($_POST["usuario"] ?? "");
    $password = $_POST["password"] ?? "";

    if ($usuario === "" || $password === "") {
        $mensaje = "Debe ingresar usuario y contraseña.";
        $tipo = "error";
    } else {
        $ldap = ldap_connect("ldap://" . AD_HOST, 389);

        ldap_set_option($ldap, LDAP_OPT_PROTOCOL_VERSION, 3);
        ldap_set_option($ldap, LDAP_OPT_REFERRALS, 0);

        $usuarioAD = $usuario . "@" . AD_DOMAIN;

        if (@ldap_bind($ldap, $usuarioAD, $password)) {
            $mensaje = "Autenticación correcta. Bienvenido, " . htmlspecialchars($usuarioAD);
            $tipo = "ok";
        } else {
            $mensaje = "Usuario o contraseña incorrectos.";
            $tipo = "error";
        }

        ldap_close($ldap);
    }
}
?>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Proyecto Redes - Login AD</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: #f3f4f6;
            margin: 0;
            padding: 0;
        }

        .contenedor {
            width: 420px;
            margin: 90px auto;
            background: white;
            padding: 25px;
            border-radius: 8px;
            box-shadow: 0 2px 10px #ccc;
        }

        h1 {
            text-align: center;
            font-size: 24px;
        }

        label {
            display: block;
            margin-top: 15px;
        }

        input {
            width: 100%;
            padding: 10px;
            margin-top: 5px;
            box-sizing: border-box;
        }

        button {
            margin-top: 20px;
            width: 100%;
            padding: 10px;
            background: #2563eb;
            color: white;
            border: none;
            cursor: pointer;
        }

        .ok {
            background: #dcfce7;
            color: #166534;
            padding: 10px;
            margin-top: 15px;
        }

        .error {
            background: #fee2e2;
            color: #991b1b;
            padding: 10px;
            margin-top: 15px;
        }

        .server {
            margin-top: 20px;
            font-size: 13px;
            color: #555;
            text-align: center;
        }
    </style>
</head>
<body>
<div class="contenedor">
    <h1>Login con Active Directory</h1>

    <form method="POST">
        <label>Usuario</label>
        <input type="text" name="usuario" placeholder="usuario1">

        <label>Contraseña</label>
        <input type="password" name="password">

        <button type="submit">Ingresar</button>
    </form>

    <?php if ($mensaje !== ""): ?>
        <div class="<?php echo $tipo; ?>">
            <?php echo $mensaje; ?>
        </div>
    <?php endif; ?>

    <div class="server">
        Servidor que atendió la solicitud:
        <strong><?php echo gethostname(); ?></strong>
    </div>
</div>
</body>
</html>