
include:
  - cosbench

stop-cosbench-controller:
  cmd.wait:
    - name: ./stop-controller.sh
    - cwd: /home/cosbench/cos
    - user: cosbench
    - onlyif: nc -z localhost 19088
    - watch:
      - file: /home/cosbench/cos/conf/controller.conf
      
cosbench-controller:
  file.managed:
    - name: /home/cosbench/cos/conf/controller.conf
    - source: salt://cosbench/controller.conf
    - template: jinja
    - user: cosbench
    - context:
        drivers:
{%- for host, hostinfo in salt['mine.get']('*', 'grains.items').items() %}
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

