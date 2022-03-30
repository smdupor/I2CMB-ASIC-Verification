from __future__ import with_statement # Python version 2.5 or later required

import cgi, generator, json, logging, os, re, rmdbdata, tempita, urlparse, vrmutils, urllib, webbrowser, sys

from BaseHTTPServer import BaseHTTPRequestHandler, HTTPServer

if sys.version_info[0] != 2 or sys.version_info[1] < 5:
    print("Regression Author requires atleast python version 2.5")
    sys.exit(1)

env_debug    = 'VRM_DEBUG' in os.environ

datafile     = 'mysuite'

arg_favicon  = os.path.join('images', 'vrm.ico')
arg_rootpage = os.path.join('pages', 'index.html')

arg_suites   = None;

#
# HTTP request handler
#
class MyHandler(BaseHTTPRequestHandler):

	def do_validate_suite_name(self, suitename):
		if not suitename:
			self.send_error(400, 'Suitename cannot be empty!')
		elif re.match('^[a-zA-Z-_0-9]+$', suitename):
			if len(suitename) > 25:
				self.send_error(400, 'Invalid Suite Name! Suite names can contain up to 25 characters')
			else:
				if suitename == 'global':
					self.send_error(400, 'Invalid Suite Name! Suites cannot have the name global')
				else:
					suites = rmdbdata.suites()
					for suite in suites:
						if suite['name'] == suitename:
							self.send_error(400, 'Duplicate Suite Name %s' % suitename)
					self.send_response(200)
		else:
			self.send_error(400, 'Invalid Suite Name! Suite names can contain only alphanumeric characters, "-", and "_"')

	def do_expand(self, suitename, filename, type=None):
		data = rmdbdata.RmdbData(suitename) if suitename else dict() # dict has a "get" method
		with open(vrmutils.find_path(filename, data.get('template'))) as f:
		
			self.send_response(200)
			if (type):
				self.send_header('Content-type', type)
			self.end_headers()

			tmp  = tempita.Template(f.read())

			vars = dict(
				data  = rmdbdata,
				debug = env_debug,
				get   = lambda key, default = '': data.get(key, default),
				gethelp   = lambda key, default = '': data.gethelp(key, default),
				suite = suitename
			)

			self.wfile.write(tmp.substitute(vars))

	def send_data(self, relpath, queryStr, type=None):
		self.send_response(200)
		if (type):
			self.send_header('Content-type', type)
		self.end_headers()

		# Return an empty list by default

		retval = []

		# Figure out WHAT to send...

		parts = relpath.split('/')

		if len(parts) == 2 or len(parts) == 3:
			if len(parts) ==3 and parts[0] == 'pages':
				parts[0] = parts[1]
				parts[1] = parts[2]
			data = rmdbdata.RmdbData(parts[0]) # 1st component is a suite name
			### Ex: http://localhost:port/suite/index.json -- return list of data-entry pages in suite

			if parts[1].startswith('index.'):
				index = os.path.join(vrmutils.find_template_dir(data.get('template')), 'index.json')

				with open(index) as f:
					retval = json.load(f)

			### Ex: http://localhost:port/suite/data.json[?key=name[&key=name]]
			###      -- return suite data (as object)

			elif parts[1].startswith('data.'):
				queryAry = urlparse.parse_qs(queryStr)

				if 'key' in queryAry: # return object containing specified keys
					retval = {}

					for key in queryAry['key']:
						retval[key] = data.get(key, '')

				else: # return entire data object
					retval = data.dump()

			### Ex: http://localhost:port/suite/keys.json[?key=name[&key=name]]
			###      -- return list of key/value pairs (deprecated)

			elif parts[1].startswith('keys.'):
				queryAry = urlparse.parse_qs(queryStr)

				for key in queryAry['keys[]']:
					retval.append({'key': key, 'value': data.get(key, '')})

		elif len(parts) == 1:

			### Ex: http://localhost:port/templates.json -- return list of templates

			if parts[0].startswith('templates.'):
				retval = vrmutils.templates()

			### Ex: http://localhost:port/suites.json -- return list of suites

			elif parts[0].startswith('suites.'):
				retval = rmdbdata.suites()

		# ...then, figure out HOW to send it

		if relpath.endswith('.json'):
			self.wfile.write(json.dumps(retval, sort_keys=True) + '\n')
		else:
			self.wfile.write(retval) # probably bogus

	def send_file(self, filename, type=None):
		with open(vrmutils.find_path(filename)) as f:
			self.send_response(200)
			if (type):
				if not type == 'application/x-gzip':
					print filename
					seconds_valid = 8600
					self.send_header('Cache-Control', "public, max-age=%d" % seconds_valid)
				self.send_header('Content-type', type)
			self.end_headers()

			self.wfile.write(f.read())

	def send_suite(self, suitename, filename):
		with generator.generate_suite(filename, suitename) as tarfile:
			self.send_file(tarfile, 'application/x-gzip')

	def send_text(self, content, type=None):
		self.send_response(200)
		if (type):
			self.send_header('Content-type', type)
		self.end_headers()

		self.wfile.write(content)

	def do_GET(self):

		try:
			logging.debug('GET: %s', self.path)

			req = urlparse.urlparse(self.path)

			relpath = re.sub('^/', '', req.path)

			if relpath.endswith('.tar'):
				match = re.match('generate/([^/]+).tar$', relpath)

				if match:
					self.send_suite(match.group(1), os.path.basename(relpath))
				else:
					self.send_error(404, 'File not found (a): %s' % relpath)

			elif relpath == '':
				self.do_expand(None, arg_rootpage, 'text/html')

			elif relpath == 'favicon.ico':
				self.send_file(arg_favicon, 'image/x-icon')

			elif relpath.endswith('.css'):
				self.send_file(relpath, 'text/css')

			elif relpath.endswith(('.htm', '.html')):
				match = re.match('(help|pages)/([^/]+)/([^/]+)$', relpath)
				if match:
					self.do_expand(match.group(2), os.path.join(match.group(1), match.group(3)), 'text/html')
				else:
					match = re.match('pages/global.htm', relpath)
					if match: 
						self.do_expand('global', relpath, 'text/html')
					else:
						self.do_expand(None, relpath, 'text/html')

			elif relpath.endswith('.ico'):
				self.send_file(relpath, 'image/x-icon')

			elif relpath.endswith('.js'):
				self.send_file(relpath, 'application/javascript')

			elif relpath.endswith('.json'):
				self.send_data(relpath, req.query, 'application/json')

			elif relpath.endswith('.png'):
				self.send_file(relpath, 'image/png')
				
			elif relpath.startswith('validate'):
				query_components = dict(qc.split("=") for qc in req.query.split("&"))
				parts = relpath.split('/')
				if parts[1] == 'suite':
					suitename = query_components['suitename']
					suitename = urllib.unquote(suitename)
					self.do_validate_suite_name(suitename)

			else:
				self.send_file(relpath, 'application/octet-stream')

		except IOError:
			self.send_error(404, 'File not found (b): %s' % self.path)

	def do_POST(self):
		try:
			ctype, pdict = cgi.parse_header(self.headers.getheader('content-type'))

			logging.debug('POST: %s (%s)', self.path, ctype)

			content = self.rfile.read(int(self.headers.getheader('content-length')))

			if ctype == 'application/json':
				logging.debug('...processing json')

				jsonContent = json.loads(content)

				if self.path in ('/get'):
					retval = []

					data = rmdbdata.RmdbData(jsonContent['suite'])

					for key in jsonContent['keys']:
						retval.append({'key': key, 'data': data.get(key, '')})

				elif self.path in ('/create'):
					rmdbdata.create(jsonContent['name'], jsonContent['template'])

				elif self.path in ('/delete'):
					rmdbdata.delete(jsonContent['name'])

				else:
					match = re.match('/pages/([^/]+)/([^./]+).htm$', self.path)
					matchglobal = re.match('/pages/global.htm$', self.path)
					

					if match or matchglobal:
						if match:
							data = rmdbdata.RmdbData(match.group(1))
						else:
							data = rmdbdata.RmdbData('global')
						for key in jsonContent:
							data.put(key, jsonContent[key])

						data.save()

					else:
						logging.warning('Unknown JSON content: %s', content)

				self.send_text('Post OK', 'text/plain')

			else:
				logging.warning('Unknown POST: URL is %s, content is %s', self.path, content)

				self.do_GET()

		except Exception as e:
			logging.error('Unknown exception: %s', e)

			self.send_error(404, 'File not found (c): %s' % self.path)

#
# Main routine -- called only if the server was invoked stand-alone
#
if __name__ == '__main__':

	import getopt, signal, subprocess, sys

	def send_help(exit_code, message = ''):
		if message:
			logging.error(message)

		print 'python', sys.argv[0], '<options>'
		print '  (-c | --cwd)            Look for content files in current directory'
		print '  (-d | --debug)          Enable additional debug messages'
		print '  (-h | --help)           Print this help message'
		print '  (-p | --port)   <port>  Specify listening port for server mode'
		print '  (-r | --root)   <path>  Path to the root HTML file of the application'
		print '  (-s | --server)         Run in server mode (do not invoke browser)'
		print '        --suites  <path>  Specify path to directory with JSON suite files'
		print '  (-l | --log)    <path>  Specify path to log file.'

		sys.exit(exit_code)

	try:
		logging.basicConfig(format = '%(levelname)s: %(message)s', level = logging.WARNING)

		# Process command-line options

		arg_port   = 0

		arg_server = False
		arg_usecwd = False
		arg_log_file = None

		opts, args = getopt.getopt(sys.argv[1:], 'cdhp:r:sl:',
			['cwd', 'debug', 'help', 'port=', 'root=', 'server', 'suites=', 'log='])

		for opt, arg in opts:
			if opt in ('-c', '--cwd'):
				arg_usecwd = True

			elif opt in ('-d', '--debug'):
				logging.getLogger().setLevel(logging.DEBUG)

			elif opt in ('-h', '--help'):
				send_help(0)

			elif opt in ('-p', '--port'):
				arg_port = int(arg)

			elif opt in ('-r', '--root'):
				arg_rootpage = arg

			elif opt in ('-s', '--server'):
				arg_server = True

			elif opt in ('--suites'):
				arg_suites = arg

			elif opt in ('-l', '--log'):
				arg_log_file = arg

		# Initialize the path for locating content files
		vrmutils.init_search_path('VRUN_AUTHOR_PATH', arg_usecwd, arg_suites)

		# Start server and browser

		server = HTTPServer(('', arg_port), MyHandler)

		port = server.socket.getsockname()[1]

		print 'Starting HTTP server on port', port, '. Once done, please press ctrl + c to close the server'

		vrmutils.init_log_file(arg_log_file)
                if arg_server:
                        print '==> Point your browser at: http://localhost:{0}/ <=='.format(port)

                        server.serve_forever()

                else:

                        if "BROWSER" not in os.environ:
                                print 'BROWSER environment variable not set, using system default.'
                                webbrowser.open('http://localhost:{0}/'.format(port))
                                server.serve_forever()
                        else:   
                                pid = os.fork()
                                if pid == 0:
                                        server.serve_forever()
                                else:
                                        try:
                                                command= os.environ['BROWSER'].split()

                                                with open(os.devnull, "w") as nowhere:
                                                        command.append('http://localhost:{0}/'.format(port))

                                                        print 'Calling:', command

                                                        retval = subprocess.call(command, stdout=nowhere, stderr=nowhere)

                                                        print command[0], 'exited with status', retval

                                                        if retval == 0:
                                                                server.serve_forever()


                                        except KeyError:
                                                print '==> Please set the BROWSER environment variable to point to your browser. <=='

                                        except IOError as (errno, strerror):
                                                print 'I/O error({0}): {1}'.format(errno, strerror)

                                        finally:
                                                print 'Terminating server process', pid
                                                os.kill(pid, signal.SIGTERM)

	except getopt.GetoptError as e:
		send_help(2, e.msg)

	except RuntimeError, message:
		print 'Runtime error: {0}'.format(message)

	except KeyboardInterrupt:
		server.socket.close()

	finally:
		logging.shutdown()
