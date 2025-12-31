import os 														# Para saber si existe una carpeta
import threading												# Para generar threads con funciones
from time import sleep 											# Parar el programa x segundos

from modules.connection import Handler_connection				# Manejador de la conexión web
from modules.database import Handler_SQL						# Manejador de la base de datos
from modules.utils import lg_prt, datetime_now, singleton		# Mostrar y Colorear texto en consola
from modules.analizer import *

from config.global_constant import *
from config.queries_database import TAG_QUERY

# TODO asdasd


@singleton
class Handler_info:
	"""	Obtener información de información desde Internet de música
		Use:
			hif = Handler_info()
			hif.start()
			hif.stop()
			del hif
	"""

	def __init__(self):
		self.report_date_inet = datetime_now()
		self.dtb = Handler_SQL(DB_FILE, TAG_QUERY)
		self.cnt = Handler_connection()
		self.STOP = False

		self.cache_country = {}		# Cache de paises y códigos
		self.data_album = {}		# Objeto diccionario / cache con los datos de la película
		self.data_artist = {}		# Objeto diccionario / cache con los datos de la película
		self.page = None

	def __del__(self):
		del self.cnt
		del self.dtb

	def start(self):
		pThr = threading.Thread(name='more_info', target=self.get_more_info, daemon=True)
		pThr.start()
		pThr.join()

	def stop(self):
		self.STOP = True
		lg_prt('y', '[▲] Stop by Interrupt')
		del self

	def get_more_info(self):

		# -------------------------------- ACTUALIZAR ARTISTAS

		# Obtener todas las filas de artista que le falten un dato de Internet
		list_artist = self.dtb.sql_execute('get_incompletes')
		if list_artist is not None:

			num_artist = len(list_artist)
			for index, row in enumerate(list_artist):

				if self.STOP:			# Parada manual
					break

				id_artist = row[0]
				name = row[1]
				country = row[2]
				urldesc = row[3]		# Para forzar actualización con URL correcto introducido a mano

				try:
					self.data_artist.clear()
					self.data_artist.update({
						'id_artist': id_artist,
						'url_discography': self.cnt.encode_url(name)
					})
					self.get_InetInfoArtist(name, urldesc)

					# Obtener code del país
					code_country = self.cache_country.get(country, None)
					if code_country is None:
						code_country = self.dtb.sql_execute('country_byname', {'name': country})
						if code_country is None:		# Si el país no existe lo inserta
							self.dtb.sql_execute('insert_country', {'name': country})
							code_country = self.dtb.cdb.lastrowid
							lg_prt('gywb', '[✔] Country inserted.', 'CODE:', code_country[0], country)
						else:
							code_country = code_country[0][0]
						self.cache_country.update({country: code_country})
					self.data_artist['id_country'] = code_country

					# Actualizar el resto de información de un artista
					self.dtb.sql_execute('update_info_artist', self.data_artist)
					lg_prt('wgv', f'[{index + 1}/{num_artist}]', '[✔] Artist Updated with more info', self.data_artist)

					# Descargar la portada del artista
					if self.data_artist['urlpicture'] is not None:
						self.download_img(self.data_artist['urlpicture'], id_artist, False)

				except Exception as e:
					lg_prt('ryr', '[✖] Error get_more_info()', f'{id_artist}, {name}, {country}, {urldesc}', e)
					if DEBUG_MODE:
						lg_prt('999', 'get_more_info', f'{id_artist}, {name}, {country}, {urldesc}')

			else:
				lg_prt('y', '[▲] Incomplete artist not found')

		# -------------------------------- ACTUALIZAR DISCOGRAFÍA

		# Buscar discos nuevos y comprobar match
		list_artist = self.dtb.sql_execute('get_all_artist_browser')
		for id_artist, urldesc, name in list_artist:
			# Obtener la discografía del artista
			lg_prt('by', 'Getting discography for', name)
			self.update_discography(id_artist, urldesc)
			# Buscar matcher album_local=album_inet y actualizar la BBDD
			self.dtb.sql_execute('search_matches')

		# Actualizar datos de albumes
		self.get_InetInfoAlbum()

	def get_InetInfoArtist(self, name, posible_url):
		# Obtener información de un artista

		if posible_url is None:
			# Buscar artista
			lg_prt('by', 'Searching URL artist of', name)
			page, status_code = self.cnt.get_page('GET', self.cnt.encode_url(URL_SEARCH_ARTIST % name))
			sleep(1)
			# Obtener la posible URL de un artista
			posible_url = searchArtist(page) if status_code == 200 else None

		if posible_url is not None:
			lg_prt('byby', 'Get info of', name, 'in', f'{URL_BASE}{posible_url}')
			# Obtener urlpicture
			page, status_code = self.cnt.get_page('GET', URL_FM_ARTIST_IMG % name)
			sleep(1)
			urlpicture = coverArtist(page) if status_code == 200 else None
			# Obtener years_active, genre, real_country
			page, status_code = self.cnt.get_page('GET', f'{URL_BASE}{posible_url}')
			sleep(1)
			result = parseArtist(page) if status_code == 200 else None
			self.data_artist.update({'urldesc': posible_url, 'urlpicture': urlpicture, 'report_date_inet': self.report_date_inet})
			self.data_artist.update(result)

		else:
			lg_prt('ryryry', '[✖]  Error searchin URL artis', name, 'URL', posible_url, 'Status', status_code)

	def update_discography(self, id_artist, urldesc):
		# Obtener toda la discografía de un artista desde el último (año) album local
		max_year = self.dtb.sql_execute('max_year_albumes', {'id_artist': id_artist})
		max_year = max_year[0][0] if max_year is not None else 999
		# Aprovecha page para actualizar album_inet
		page, status_code = self.cnt.get_page('GET', f'{URL_BASE}{urldesc}')
		discography = parseDiscography(page, id_artist, max_year)
		if discography is not None:
			lg_prt('vywyw', '[▲] Inserting maxively discography from the internet.', 'Total:', len(discography), 'URL', f'{URL_BASE}{urldesc}')
			self.dtb.sql_execute_many('insert_albumes_inet', discography)
			lg_prt('g', '[✔] Inserting maxively completed')
		else:
			lg_prt('yg', '[▲] Albumes inet not found.', 'Possible complete discography')

	def get_InetInfoAlbum(self):
		# Buscar albumes incompletos
		list_album = self.dtb.sql_execute('get_incompletes_album')
		num_album = len(list_album)
		last_id_artist = None
		lg_prt('byb', 'Searching Cover album and more info (incompletes) for', num_album, 'albumes')

		# Recorrer albumes incompletos
		for index, album in enumerate(list_album):
			id_album = album[0]
			title = album[1]
			urldesc = album[3]										# Para forzar actualización con URL correcto manual
			id_artist = album[5]

			# Extraer discografía FM de un artista
			if id_artist != last_id_artist:
				name = album[2]
				url_discography = URL_FM_DISCOGRAPHY % album[4]		# Para forzar actualización con URL correcto manual
				lg_prt('vywyv', '\nGetting FM discograpy of', 'Artist', name, 'url_discography', url_discography)

				# Buscar discografía en fm
				page, status_code = self.cnt.get_page('GET', url_discography)
				sleep(1)
				discography = getFMDiscography(page)
				if discography is None:		# Salir si no encuentra la discografía o ya está descargada
					continue
				last_id_artist = id_artist

			lg_prt('wby', f'[{index}/{num_album}]', 'Searching match for', title)
			# Comparar discografía local y discografía FM y actualizar coincidencias
			for posible_title, posible_url, urlpicture in discography:
				# Hay un match entre albul local e inet
				if title.lower() == posible_title.lower():
					# Forzar URL de discografía
					if urldesc is None:
						urldesc = posible_url

					# TODO release, duration, num_tracks, desde la urldesc
					self.data_album.clear()
					self.data_album.update({
						'urldesc': urldesc,
						'urlpicture': urlpicture,
						'id_album': id_album
					})

					lg_prt('yvbyw', '[▲] Match local inet.', 'Updating info for', title, 'Data', self.data_album)
					self.dtb.sql_execute('update_album', self.data_album)

					# Descargar la portada del artista
					if urlpicture is not None:
						self.download_img(urlpicture, id_album, True)

					break		# No seguir comparando ese album

	def check_img_in_hdd(self):
		# Comprobar que las portadas de películas estan en hdd
		# 72e43a38898e88c285a131f497ae7092.jpg
		list_album = self.dtb.sql_execute('get_urlpicture_album')
		lg_prt('r', '[▲] Files of album not found in HDD:')
		for row in list_album:
			id_artist = row[0]
			urlpicture = row[2]
			self.download_img(urlpicture, id_artist, True)

		list_artist = self.dtb.sql_execute('get_urlpicture_artist')
		lg_prt('r', '[▲] Files of artist not found in HDD:')
		for row in list_artist:
			id_artist = row[0]
			urlpicture = row[1]
			self.download_img(urlpicture, id_artist, False)

	# Descargar la portada de la película
	def download_img(self, urlpicture, id_folder, is_album=False):
		''' Descarga una imagen a partir de la url y la guarda en la carpeta de su artista
			Args:
				urlpicture (str):	Artist	i/u/avatar170s/4af13bdef4aa46dcb2d689e6ce05b0a9.jpg
									Album	i/u/770x0/72e43a38898e88c285a131f497ae7092.jpg
				id_folder (int): 	14
		'''
		print(urlpicture)

		name, extension = os.path.splitext(urlpicture)						# Obtener nombre y extensión del archivo

		if is_album:
			path = PATH_ALBUMS_COVERS % id_folder		# ./app/images/covers/artist/99/album/
			path_file = path + urlpicture		# './app/images/covers/artist/99/album/4af13bdef4aa46dcb2d689e6ce05b0a9.jpg'
			urlpicture = URL_FM_ALBUMS_COVER % urlpicture
			path_file_cmp = f'{path}{name}_cmp{extension}'

		else:
			path = PATH_ARTIST_COVERS + str(id_folder)
			path_file = f'{path}/{urlpicture}'
			urlpicture = URL_FM_ARTIST_COVER % urlpicture
			path_file_cmp = f'{path}/{name}_cmp{extension}'

		lg_prt('t', path_file)
		# Para comprobar archivo comprimido con nombre comprimido
		if os.path.isfile(path_file_cmp) or os.path.isfile(path_file):		# Comprobar si ya existe la imagen
			lg_prt('yv', '[▲] Imagen exits.', path_file)
			return True

		try:
			page, status_code = self.cnt.get_page('GET', urlpicture)
			sleep(1)
			if status_code == 200:
				if not os.path.exists(path):								# Crear directiorio si no existe
					os.makedirs(path)
				with open(path_file, 'wb') as f:							# Guardar la imagen
					f.write(page.content)

			lg_prt('gyvy', '[✔] Img downloaded.', path_file, 'is_album', is_album)
		except Exception as e:
			lg_prt('ryryr', '[✖] Error download_img()', urlpicture, 'in', path_file, e)
			if DEBUG_MODE:
				lg_prt('999', 'download_img()', f'{urlpicture} in {path_file}')
