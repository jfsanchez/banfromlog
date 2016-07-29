 banfromlog: examina los logs para prevenir ataques de tipo brute force por SSH
    y prohibe conectar a la ips con muchos intentos a tu puerto 22.

Copyright (C) 2005 Jose Sanchez <jose_at_serhost_dot_com>

INDEX
---------------------------------------------------------------------------

	QUE ES BANFROMLOG
	POR QUE ES IMPORTANTE?
	COMO INSTALARLO

---------------------------------------------------------------------------


QUE ES BANFROMLOG
=================

	BanFromLog es un simple script para logear cualquier intento de conexion
	con un usuario inexistente al SSHD.

	Logea esas ips a una base de datos (definida por ti) y puede actuar como 
	firewall proactivo con un par de lineas (explicadas mas abajo) en el crond.

POR QUE ES IMPORTANTE?
======================

	Es cierto que si solo tienes un usuario, no necesitas este script, pero
	cuando tienes cientos o incluso miles de usuarios, muchos de ellos pueden
	tener contraseñas inseguras (por mucho que les adviertas o que hagas modificaciones
	al programa passwd para intentar evitarlo).

	Tambien puedes recibir otro tipo de ataques via SSH despues de esos intentos.	

	Tu velocidad de CPU puede verse disminuida por culpa de estos ataques que incluso
	se producen a la vez por medio de zoombies.	

COMO INSTALAR BANFROMLOG
========================

	Primero necesitas MySQL o sqlite instalado y acceso de root.

	Si tienes MySQL permite a un usuario conectar a localhost y insertar/seleccionar de una base de datos
	sin contraseña.	Edita el script banfromlog y cambia los valores por defecto: usuario, base de datos, etc
	luego crea la estructura en la base de datos definida en structure.mysql

	Despues tendras que borrar estas lineas en el script, asi que editalo y borralas:

		# Remove or comment this two lines AFTER CONFIGURING this script
		echo "Configure me first!. Edit me and remove this comment to use me"
		exit 0;
		#************************************************

	Llamar a "banfromlog log2db" y "banfromlog protect" cada hora (o cada 10 minutos) de la siguiente forma:

		Primero editaremos el /etc/crontab
			# nano /etc/crontab

		Luego, para ejecutar banfromlog cada hora, pondremos
			50 *    * * *   root    /root/banfromlog log2db
			55 *    * * *   root    /root/banfromlog protect

		Donde /root/banfromlog es la ruta al banfromlog y 55 * significa cada hour a los 55 minutos

	Lo he configurado para ejecutarse cada 10 minutos y funciona bien en un PII con 256 de RAM

	ADVERTENCIA!!: Si se ha aceptado el trafico al puerto 22 en una regla anterior del iptables, se debe tener
	cuidado y ejecutar en el orden correcto para que banfromlog funcione correctamente.
	Mas informacion en: http://www.netfilter.org
	
	ADVERTENCIA2: BANFROMLOG ejecutara la prohibición incluso a las ips ya prohibidas, es recomendable que regeneres
	todo el firewall cada X tiempo, llamando a banfromlog en el sitio adecuado. Esto no es un bug, es una feature xD.
