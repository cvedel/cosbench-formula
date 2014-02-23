
{% set version = salt['pillar.get']('cosbench:package:version', '0.4.0.a1') %}
{% set source = salt['pillar.get']('cosbench:package:source', 'https://github.com/intel-cloud/cosbench/releases/download/v0.4.0.a1/0.4.0.a1.zip') %}
{% set hash = salt['pillar.get']('cosbench:package:sha1', '34d1702e6b20281ae704f7d2cb706427ae550cbf') %}

java-1.7.0-openjdk:
  pkg.installed

curl:
  pkg.installed

unzip:
  pkg.installed

nc:
  pkg.installed

cosbench:
  user.present

/home/cosbench/{{version}}.zip:
  file:
    - managed
    - source: {{ source }}
    - source_hash: sha1={{ hash }}
    - require:
      - user: cosbench

/home/cosbench/{{version}}:
  cmd:
    - run
    - name: unzip /home/cosbench/{{version}}.zip
    - cwd: /home/cosbench
    - unless: test -d /home/cosbench/{{version}}
    - require:
      - file: /home/cosbench/{{version}}.zip
      - pkg: unzip
  file.directory:
    - user: cosbench
    - group: cosbench
    - recurse:
      - user
      - group
    - require:
      - cmd: /home/cosbench/{{version}}

/home/cosbench/cos:
  file.symlink:
    - target: /home/cosbench/{{version}}
    - require:
      - cmd: /home/cosbench/{{version}}

# option -q does not exist for CentOS nc
fix-tools-param:
  file.comment:
    - name: /home/cosbench/cos/cosbench-start.sh
    - regex: ^TOOL_PARAMS=
    - require:
      - file: /home/cosbench/cos

{% for script in ['cli.sh', 'start-all.sh', 'stop-all.sh', 'start-controller.sh', 'stop-controller.sh', 'start-driver.sh', 'stop-driver.sh', 'cosbench-start.sh', 'cosbench-stop.sh'] %}
/home/cosbench/cos/{{script}}:
  file.managed:
    - mode: 0755
    - require:
      - file: /home/cosbench/cos
      - pkg: nc
{% endfor %}

