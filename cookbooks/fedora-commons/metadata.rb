name             'fedora-commons'
maintainer       'Steven K. Ng'
maintainer_email 'steven@nomadicoder.com'
license          'Apache 2.0'
description      'Installs/Configures fedora-commons'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'
recipe           'fedora-commons', 'Recipe to download, install, and configure a fedora server'

depends 'mysql',         '~> 4.0.14'
