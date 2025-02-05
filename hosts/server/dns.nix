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
    data = ''
      ns1.${domain}. admin.${domain}. (
            2021090101
            900
            900
            2592000
            900
          )'';
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
    class = "IN";
    type = "A";
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
    name = "www";
    inherit ttl;
    class = "IN";
    type = "CNAME";
    data = domain;
  }
  {
    name = "@";
    inherit ttl;
    class = "IN";
    type = "MX";
    data = "10 glacier.mxrouting.net.";
  }
  {
    name = "@";
    inherit ttl;
    class = "IN";
    type = "MX";
    data = "20 glacier-relay.mxrouting.net.";
  }
  {
    name = "@";
    inherit ttl;
    class = "IN";
    type = "TXT";
    data = "\"v=spf1 include:mxroute.com -all\"";
  }
  {
    name = "x._domainkey";
    inherit ttl;
    class = "IN";
    type = "TXT";
    data = ''
      (
            "v=DKIM1;"
            "k=rsa;"
            "p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEArLEUDzMAOlQaKm7Ov5hJ4vgET"
            "JN7vMbwb2qr4mUI5nU6zpfH/609NV63mZfxTlqOKAan0zee9Yizrc1UgnGE8Y8Hh34vwPo2"
            "D2rMA0xuhyDiOVoLvw7AQIp38WeT7Gj7idm3lPy0iDgYIxIZaoQQ9u4GW3XnZmhbHUGURil"
            "SDp0kDW6m1i+fPxD0XEyrYLzwYr85KKeWKZJEn6qRk5ogd9n7p7xJa24gvNpMSZTZHvSG9C"
            "0EMnorLqlHw5i3HMA99IO6RjZK3Ntoo5YktTbuq9NP+ecpDt3xHC7HOWAGetL8tPC7HZbOF"
            "+SCcFXp4LGZpruAEBnzbAbimz0B1va5LQIDAQAB;"
          )'';
  }
  {
    name = "_dmarc";
    inherit ttl;
    class = "IN";
    type = "TXT";
    data = ''
      (
            "v=DMARC1;"
            "p=reject;"
            "pct=100;"
            "rua=mailto:admin@${domain};";
          )'';
  }
]
