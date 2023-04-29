FROM rustprooflabs/pgosm-flex

COPY ./db /app/faker/db
COPY ./faker.ini /app/flex-config/layerset/
COPY ./run_faker.sh /app/
COPY ./run_faker.sql /app/
