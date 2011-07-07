require 'yaml'
SETTINGS = YAML.load(Raemon.root.join('config/settings.yml').read)[Raemon.env]
