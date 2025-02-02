domain:
let
  ttl = 3600;
in
[
  {
    name = "@";
    inherit ttl;
    class = "IN";
    type = "SOA";
    data = "ns1.${domain}. admin.${domain}. 2021090101 900 900 2592000 900";
  }
  {
    name = "@";
    inherit ttl;
    class = "IN";
    type = "NS";
    data = "ns1.${domain}.";
  }
  {
    name = "ns1";
    inherit ttl;
    class = "IN"; type = "A";
    data = "193.108.52.52";
  }
  {
    name = "ns1";
    inherit ttl;
    class = "IN";
    type = "AAAA";
    data = "2001:1600:13:101::16e3";
  }
  {
    name = "@";
    inherit ttl;
    class = "IN";
    type = "A";
    data = "193.108.52.52";
  }
  {
    name = "@";
    inherit ttl;
    class = "IN";
    type = "AAAA";
    data = "2001:1600:13:101::16e3";
  }
  {
    name = "@";
    inherit ttl;
    class = "IN";
    type = "MX";
    data = "10 ${domain}.";
  }
  {
    name = "@";
    inherit ttl;
    class = "IN";
    type = "TXT";
    data = "\"v=spf1 mx -all\"";
  }
]
