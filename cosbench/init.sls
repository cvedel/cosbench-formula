
{% from "cosbench/map.jinja" import cosbench with context %}

{% set version = salt['pillar.get']('cosbench:package:version', '0.4.0.a1') %}
{% set source = salt['pillar.get']('cosbench:package:source', 'https://github.com/intel-cloud/cosbench/releases/download/v0.4.0.a1/0.4.0.a1.zip') %}
{% set hash = salt['pillar.get']('cosbench:package:sha1', '34d1702e6b20281ae704f7d2cb706427ae550cbf') %}

install pre requisites:
  pkg.installed:
    - pkgs:
      - {{ cosbench.jdk }}
      - {{ cosbench.netcat }}
      - curl
      - unzip

create cosbench user:
  user.present:
    - name: cosbench

/home/cosbench/{{version}}:
  archive.extracted:
    - name: /home/cosbench
    - source: {{ source }}
    - source_hash: sha1={{ hash }}
    - archive_format: zip
    - user: cosbench
    - group: cosbench
    - if_missing: /home/cosbench/{{version}}
    - keep: True
    - require:
      - user: create cosbench user
  file.directory:
    - user: cosbench
    - group: cosbench
    - recurse:
      - user
      - group
    - require:
      - archive: /home/cosbench/{{version}}

/home/cosbench/cos:
  file.symlink:
    - target: /home/cosbench/{{version}}
    - user: cosbench
    - group: cosbench
    - require:
      - archive: /home/cosbench/{{version}}

{% if grains['os_family'] == 'RedHat' %}
# option -q does not exist for CentOS nc
fix-tools-param:
  file.comment:
    - name: /home/cosbench/cos/cosbench-start.sh
    - regex: ^TOOL_PARAMS=
    - require:
      - file: /home/cosbench/cos
{% endif %}

{% for script in ['cli.sh', 'start-all.sh', 'stop-all.sh', 'start-controller.sh', 'stop-controller.sh', 'start-driver.sh', 'stop-driver.sh', 'cosbench-start.sh', 'cosbench-stop.sh'] %}
/home/cosbench/cos/{{script}}:
  file.managed:
    - replace: False
    - mode: 0755
    - require:
      - file: /home/cosbench/cos
      - pkg: install pre requisites
{% endfor %}

