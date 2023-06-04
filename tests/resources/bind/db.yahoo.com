$ORIGIN yahoo.com.
$TTL 60
;                 email    serial      refresh  retry  exp   ttl
@    IN SOA  ns ( admin    1957100401  1800     600    3600  900 )
@    IN NS   ns
@    IN MX   10 mail
ns   IN A    172.25.0.2
mail IN A    172.25.0.6

