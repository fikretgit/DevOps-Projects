FROM postgres

RUN mkdir -p /tmp/psql_data/

COPY ./init.sql /docker-entrypoint-initdb.d/

EXPOSE 5432