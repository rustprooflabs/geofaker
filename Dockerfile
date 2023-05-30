FROM rustprooflabs/pgosm-flex

# Install pgfaker extension
RUN wget https://github.com/rustprooflabs/pgfaker/releases/download/0.0.1/pgfaker_0.0.1_debian-11_pg15_amd64.deb \
        -O /tmp/pgfaker.deb \
    && dpkg -i --force-overwrite /tmp/pgfaker.deb


COPY ./db /app/faker/db
COPY ./faker.ini /app/flex-config/layerset/

COPY ./app/* /app/

