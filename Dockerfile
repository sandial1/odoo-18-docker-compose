FROM odoo:18

USER root
COPY entrypoint.sh /entrypoint.sh
RUN chmod +777 /entrypoint.sh

USER odoo

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 8069 8072
