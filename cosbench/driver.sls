
include:
  - cosbench

{%- set interface = salt['pillar.get']('cosbench:interface', 'eth0') %}
{%- set ip = salt['network.ip_addrs'](interface=interface)[0] %}
{%- set url = 'http://' + ip + ':18088/driver' %}
{%- set identifier = salt['pillar.get']('cosbench:identifier', grains['host']) %}

stop-cosbench-driver:
  cmd.wait:
    - name: ./stop-driver.sh
    - cwd: /home/cosbench/cos
    - user: cosbench
    - onlyif: nc -w 1 -z {{ ip }} 18088
    - watch:
      - file: /home/cosbench/cos/conf/driver.conf
      
cosbench-driver:
  file.managed:
    # substitute the IP address in the driver configuration file
    - name: /home/cosbench/cos/conf/driver.conf
    - source: salt://cosbench/driver.conf
    - template: jinja
    - user: cosbench
    - context:
        identifier: {{ identifier }}
        url: {{ url }}
    - require:
      - file: /home/cosbench/cos
  grains.present:
    # set a grain for this driver's URL so it can be mined by the controller
    - name: cosbench_driver_url
    - value: {{ url }}
  cmd.run:
    - name: ./start-driver.sh
    - cwd: /home/cosbench/cos
    - user: cosbench
    - unless: nc -w 1 -z {{ ip }} 18088
    - require:
      - file: /home/cosbench/cos/conf/driver.conf

cosbench-driver-identifier:
  grains.present:
    # set a grain for this driver's identifier so it can be mined by the controller
    - name: cosbench_driver_identifier
    - value: {{ identifier }}
