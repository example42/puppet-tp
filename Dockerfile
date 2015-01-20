FROM example42/ubuntu-1404

RUN puppet apply -e 'tp::install { redis: }'

