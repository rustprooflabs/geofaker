FROM rustprooflabs/pgosm-flex

# Install pgfaker extension
RUN wget https://github.com/rustprooflabs/pgfaker/releases/download/0.0.3/pgfaker_0.0.3_debian-13_pg18_amd64.deb \
        -O /tmp/pgfaker.deb \
    && dpkg -i --force-overwrite /tmp/pgfaker.deb


COPY ./db /app/faker/db
COPY ./faker.ini /app/flex-config/layerset/

COPY ./app/* /app/

