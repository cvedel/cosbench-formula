
include:
  - cosbench

{%- set group = salt['pillar.get']('cosbench:group', 'default') %}

stop-cosbench-controller:
  cmd.wait:
    - name: ./stop-controller.sh
    - cwd: /home/cosbench/cos
    - user: cosbench
    - onlyif: nc -z localhost 19088
    - watch:
      - file: /home/cosbench/cos/conf/controller.conf
      - file: /home/cosbench/cos/conf/cosbench-users.xml
      
/home/cosbench/cos/conf/cosbench-users.xml:
  file.managed:
    - source: salt://cosbench/cosbench-users.xml
    - template: jinja
    - user: cosbench
    - mode: 600

cosbench-controller:
  file.managed:
    - name: /home/cosbench/cos/conf/controller.conf
    - source: salt://cosbench/controller.conf
    - template: jinja
    - user: cosbench
    - context:
        drivers:
{%- for host, hostinfo in salt['mine.get']('*', 'grains.items').items() %}
{%- if hostinfo.has_key('cosbench_group') and hostinfo['cosbench_group'] == group %}
{%- if hostinfo.has_key('cosbench_driver_url') %}
{%- if hostinfo.has_key('cosbench_driver_identifier') %}
          -
            - {{ hostinfo['cosbench_driver_identifier'] }}
            - {{ hostinfo['cosbench_driver_url'] }}
{%- else %}
          -
            - driver{{ loop.index }}
            - {{ hostinfo['cosbench_driver_url'] }}
{%- endif %}
{%- endif %}
{%- endif %}
{%- endfor %}
    - require:
      - file: /home/cosbench/cos
  cmd.run:
    - name: ./start-controller.sh
    - cwd: /home/cosbench/cos
    - user: cosbench
    - unless: nc -z localhost 19088
    - require:
      - file: /home/cosbench/cos/conf/controller.conf
      - file: /home/cosbench/cos/conf/cosbench-users.xml

