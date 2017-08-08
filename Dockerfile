FROM rabbitmq
COPY cluster.sh /cluster.sh
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["/cluster.sh"]
