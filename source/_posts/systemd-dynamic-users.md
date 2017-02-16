---
title: systemd dynamic users
date: 2017-02-16
tags: Devops
---

systemd 232 introduced a really cool feature that allows running as a dynamically allocated user with `DynamicUser=yes`.

Both group and user are set to a free ID in the range  61184...65519. E.g.:

{% codeblock lang:console line_number:false %}
$ sudo systemd-run -p DynamicUser=yes -r -t id
Running as unit: run-re94d829d72f74046a1f402348bef2487.service
Press ^] three times within 1s to disconnect TTY.
uid=61791 gid=61791 groups=61791
{% endcodeblock %}
