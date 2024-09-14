{
  actioncable = {
    dependencies = ["actionpack" "activesupport" "nio4r" "websocket-driver" "zeitwerk"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0ifiz4nd6a34z2n8lpdgvlgwziy2g364b0xzghiqd3inji0cwqp1";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "7.1.3.2";
  };
  actionmailbox = {
    dependencies = ["actionpack" "activejob" "activerecord" "activestorage" "activesupport" "mail" "net-imap" "net-pop" "net-smtp"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1adqnf5zc4fdr71ykxdv5b50h7n4xfvrc0qcgwmgidi0cxkzx4r4";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "7.1.3.2";
  };
  actionmailer = {
    dependencies = ["actionpack" "actionview" "activejob" "activesupport" "mail" "net-imap" "net-pop" "net-smtp" "rails-dom-testing"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "012mxn5dfhwbssrckw6kvf851m6rlfa87n4nikk28g05ydfsvcys";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "7.1.3.2";
  };
  actionpack = {
    dependencies = ["actionview" "activesupport" "nokogiri" "racc" "rack" "rack-session" "rack-test" "rails-dom-testing" "rails-html-sanitizer"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0n1v4r5cyac5wfdlf8bly45mnh60vbp067yjpkyb05vyszamiydq";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "7.1.3.2";
  };
  actiontext = {
    dependencies = ["actionpack" "activerecord" "activestorage" "activesupport" "globalid" "nokogiri"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0an5sfy96cbd7f43igq47h3m228ivngqjj40gj6iqllhjhchgs7c";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "7.1.3.2";
  };
  actionview = {
    dependencies = ["activesupport" "builder" "erubi" "rails-dom-testing" "rails-html-sanitizer"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1kq9b4xnwiknjqg4y6ixvv0cf1z0dcxs68inc8bx05s0fqrim6rn";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "7.1.3.2";
  };
  activejob = {
    dependencies = ["activesupport" "globalid"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "08gjywvd65yzgjw7ynsgvi00scxc4fmgj70wajn7wsdqx00hbafj";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "7.1.3.2";
  };
  activemodel = {
    dependencies = ["activesupport"];
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0p3ibps515151ja4gadrhh8frvjvvq4h5fpxw2acccv3z5i553hh";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "7.1.3.2";
  };
  activerecord = {
    dependencies = ["activemodel" "activesupport" "timeout"];
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0ww1qxn12nlp0ivysq0pxj6cvajf0fbq781fr4pqx5206c690wj8";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "7.1.3.2";
  };
  activestorage = {
    dependencies = ["actionpack" "activejob" "activerecord" "activesupport" "marcel"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "09wp0qqp7xr31ipcv42bs81fmyksz9l3jmraryf53qjsbbqpfdr8";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "7.1.3.2";
  };
  activesupport = {
    dependencies = ["base64" "bigdecimal" "concurrent-ruby" "connection_pool" "drb" "i18n" "minitest" "mutex_m" "tzinfo"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0blbbf2x7dn7ar4g9aij403582zb6zscbj48bz63lvaamsvlb15d";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "7.1.3.2";
  };
  addressable = {
    dependencies = ["public_suffix"];
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0irbdwkkjwzajq1ip6ba46q49sxnrl2cw7ddkdhsfhb6aprnm3vr";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.8.6";
  };
  ast = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "04nc8x27hlzlrr5c2gn7mar4vdr0apw5xg22wp6m8dx3wqr04a0y";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.4.2";
  };
  backport = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0xbzzjrgah0f8ifgd449kak2vyf30micpz6x2g82aipfv7ypsb4i";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.2.0";
  };
  base64 = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "01qml0yilb9basf7is2614skjp8384h2pycfx86cr8023arfj98g";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.2.0";
  };
  benchmark = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0wghmhwjzv4r9mdcny4xfz2h2cm7ci24md79rvy2x65r4i99k9sc";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.3.0";
  };
  bigdecimal = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0cq1c29zbkcxgdihqisirhcw76xc768z2zpd5vbccpq0l1lv76g7";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "3.1.7";
  };
  bootsnap = {
    dependencies = ["msgpack"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0iqkzby0fdgi786m873nm0ckmc847wy9a4ydinb29m7hd3fs83kb";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.17.0";
  };
  brakeman = {
    dependencies = ["racc"];
    groups = ["development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1ahkss5xpdw7vwykyd5kba74cs4r987fcn7ad5qvzhzhqdariqvy";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "6.1.1";
  };
  builder = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "045wzckxpwcqzrjr353cxnyaxgf0qg22jh00dcx7z38cys5g1jlr";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "3.2.4";
  };
  byebug = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0nx3yjf4xzdgb8jkmk2344081gqr22pgjqnmjg2q64mj5d6r9194";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "11.1.3";
  };
  capybara = {
    dependencies = ["addressable" "matrix" "mini_mime" "nokogiri" "rack" "rack-test" "regexp_parser" "xpath"];
    groups = ["test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "114qm5f5vhwaaw9rj1h2lcamh46zl13v1m18jiw68zl961gwmw6n";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "3.39.2";
  };
  ci_reporter = {
    dependencies = ["builder" "rexml"];
    groups = ["test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0qcafasmjjr8a5gzr4k92ncm6h2943skwllhjzwz8spawdwc7dla";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.1.0";
  };
  ci_reporter_rspec = {
    dependencies = ["ci_reporter" "rspec"];
    groups = ["test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1qbx8njdmrs55qpl068mjydd21pkmp12z7f6b7wqp3s15gw72mds";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.0.0";
  };
  coderay = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0jvxqxzply1lwp7ysn94zjhh57vc14mcshw1ygw14ib8lhc00lyw";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.1.3";
  };
  concurrent-ruby = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1qh1b14jwbbj242klkyz5fc7npd4j0mvndz62gajhvl1l3wd7zc2";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.2.3";
  };
  connection_pool = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1x32mcpm2cl5492kd6lbjbaf17qsssmpx9kdyr7z1wcif2cwyh0g";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.4.1";
  };
  content_disposition = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "05m5ipc81fj2pphlz1ms1yxq80ymilfjhprz790lafjlq6lks5da";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.0.0";
  };
  crack = {
    dependencies = ["rexml"];
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1cr1kfpw3vkhysvkk3wg7c54m75kd68mbm9rs5azdjdq57xid13r";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.4.5";
  };
  crass = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0pfl5c0pyqaparxaqxi6s4gfl21bdldwiawrc0aknyvflli60lfw";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.0.6";
  };
  database_cleaner = {
    dependencies = ["database_cleaner-active_record"];
    groups = ["test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1507hrvzcq7d0spnffmxbihqpnn1lgkgdbbrplb3l4f76l5m0mp3";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.0.2";
  };
  database_cleaner-active_record = {
    dependencies = ["activerecord" "database_cleaner-core"];
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "12hdsqnws9gyc9sxiyc8pjiwr0xa7136m1qbhmd1pk3vsrrvk13k";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.1.0";
  };
  database_cleaner-core = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0v44bn386ipjjh4m2kl53dal8g4d41xajn2jggnmjbhn6965fil6";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.0.1";
  };
  date = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "149jknsq999gnhy865n33fkk22s0r447k76x9pmcnnwldfv2q7wp";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "3.3.4";
  };
  diff-lcs = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0rwvjahnp7cpmracd8x732rjgnilqv2sx7d1gfrysslc3h039fa9";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.5.0";
  };
  docile = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1lxqxgq71rqwj1lpl9q1mbhhhhhhdkkj7my341f2889pwayk85sz";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.4.0";
  };
  dotenv = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1n0pi8x8ql5h1mijvm8lgn6bhq4xjb5a500p5r1krq4s6j9lg565";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.8.1";
  };
  dotenv-rails = {
    dependencies = ["dotenv" "railties"];
    groups = ["development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0v0gcbxzypcvy6fqq4gp80jb310xvdwj5n8qw9ci67g5yjvq2nxh";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.8.1";
  };
  down = {
    dependencies = ["addressable"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0hhv17mjc34ihp4a0myid7kbg1ibly73gh3jv174bdsidng363h7";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "5.4.1";
  };
  drb = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0h5kbj9hvg5hb3c7l425zpds0vb42phvln2knab8nmazg2zp5m79";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.2.1";
  };
  e2mmap = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0n8gxjb63dck3vrmsdcqqll7xs7f3wk78mw8w0gdk9wp5nx6pvj5";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.1.0";
  };
  erubi = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "08s75vs9cxlc4r1q2bjg4br8g9wc5lc5x5vl0vv4zq5ivxsdpgi7";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.12.0";
  };
  et-orbi = {
    dependencies = ["tzinfo"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1d2z4ky2v15dpcz672i2p7lb2nc793dasq3yq3660h2az53kss9v";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.2.7";
  };
  factory_bot = {
    dependencies = ["activesupport"];
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1glq677vmd3xrdilcx6ar8sdaysm9ldrppg34yzw43jzr6dx47fp";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "6.4.5";
  };
  factory_bot_rails = {
    dependencies = ["factory_bot" "railties"];
    groups = ["test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1j6w4rr2cb5wng9yrn2ya9k40q52m0pbz47kzw8xrwqg3jncwwza";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "6.4.3";
  };
  faraday = {
    dependencies = ["faraday-em_http" "faraday-em_synchrony" "faraday-excon" "faraday-httpclient" "faraday-multipart" "faraday-net_http" "faraday-net_http_persistent" "faraday-patron" "faraday-rack" "faraday-retry" "ruby2_keywords"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1c760q0ks4vj4wmaa7nh1dgvgqiwaw0mjr7v8cymy7i3ffgjxx90";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.10.3";
  };
  faraday-em_http = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "12cnqpbak4vhikrh2cdn94assh3yxza8rq2p9w2j34bqg5q4qgbs";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.0.0";
  };
  faraday-em_synchrony = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1vgrbhkp83sngv6k4mii9f2s9v5lmp693hylfxp2ssfc60fas3a6";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.0.0";
  };
  faraday-excon = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0h09wkb0k0bhm6dqsd47ac601qiaah8qdzjh8gvxfd376x1chmdh";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.1.0";
  };
  faraday-httpclient = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0fyk0jd3ks7fdn8nv3spnwjpzx2lmxmg2gh4inz3by1zjzqg33sc";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.0.1";
  };
  faraday-multipart = {
    dependencies = ["multipart-post"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "09871c4hd7s5ws1wl4gs7js1k2wlby6v947m2bbzg43pnld044lh";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.0.4";
  };
  faraday-net_http = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1fi8sda5hc54v1w3mqfl5yz09nhx35kglyx72w7b8xxvdr0cwi9j";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.0.1";
  };
  faraday-net_http_persistent = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0dc36ih95qw3rlccffcb0vgxjhmipsvxhn6cw71l7ffs0f7vq30b";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.2.0";
  };
  faraday-patron = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "19wgsgfq0xkski1g7m96snv39la3zxz6x7nbdgiwhg5v82rxfb6w";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.0.0";
  };
  faraday-rack = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1h184g4vqql5jv9s9im6igy00jp6mrah2h14py6mpf9bkabfqq7g";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.0.0";
  };
  faraday-retry = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "153i967yrwnswqgvnnajgwp981k9p50ys1h80yz3q94rygs59ldd";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.0.3";
  };
  faraday_middleware = {
    dependencies = ["faraday"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1bw8mfh4yin2xk7138rg3fhb2p5g2dlmdma88k82psah9mbmvlfy";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.2.0";
  };
  fugit = {
    dependencies = ["et-orbi" "raabro"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1cm2lrvhrpqq19hbdsxf4lq2nkb2qdldbdxh3gvi15l62dlb5zqq";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.8.1";
  };
  gds-sso = {
    dependencies = ["oauth2" "omniauth" "omniauth-oauth2" "plek" "rails" "warden" "warden-oauth2"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1m5gp18ahx7vfylcmpcjx455s88cz04i4dy1w75x4ypp2fi5ha2l";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "18.1.0";
  };
  globalid = {
    dependencies = ["activesupport"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1sbw6b66r7cwdx3jhs46s4lr991969hvigkjpbdl7y3i31qpdgvh";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.2.1";
  };
  google-protobuf = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1mnxzcq8kmyfb9bkzqnp019d1hx1vprip3yzdkkha6b3qz5rgg9r";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "3.25.3";
  };
  googleapis-common-protos-types = {
    dependencies = ["google-protobuf"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0lg51gh8n6c0a38vin94zf0k9qz32hd9y8wqjpqljnkhjfzgpkix";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.14.0";
  };
  govspeak = {
    dependencies = ["actionview" "addressable" "govuk_publishing_components" "htmlentities" "i18n" "kramdown" "nokogiri" "rinku" "sanitize"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0f1v9ialkha26magkzsljxsd5jyfpf32p3i1yp4ip91kb31lgk01";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "8.3.4";
  };
  govuk-components = {
    dependencies = ["html-attributes-utils" "pagy" "view_component"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "14s057177g2bkxfj21yq20h3vlrsarvv1nsj5wzv7yj85nc5xw8w";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "5.3.2";
  };
  govuk_app_config = {
    dependencies = ["logstasher" "opentelemetry-exporter-otlp" "opentelemetry-instrumentation-all" "opentelemetry-sdk" "plek" "prometheus_exporter" "puma" "rack-proxy" "sentry-rails" "sentry-ruby" "statsd-ruby"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1p3n1kw58xdx7vffm5fymslhxqz4nkxjj2rbnid8iza8yd3ldm4r";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "9.10.0";
  };
  govuk_design_system_formbuilder = {
    dependencies = ["actionview" "activemodel" "activesupport" "html-attributes-utils"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0r07hamq5agn43iyd1ffzxsc84arrjgq2wxjb1jfvf8sxcq6mdcf";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "5.3.3";
  };
  govuk_personalisation = {
    dependencies = ["plek" "rails"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0xs6miyx0kmb4gkl5h7ajh5qn4955bqzcciddy845m013vx0y05i";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.16.0";
  };
  govuk_publishing_components = {
    dependencies = ["govuk_app_config" "govuk_personalisation" "kramdown" "plek" "rails" "rouge" "sprockets" "sprockets-rails"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1yrvkshb4b4hzx5b1n3jlh8x54bcm8cg5sm1vm3bqnfdwazn4cj6";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "38.1.0";
  };
  hashdiff = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1nynpl0xbj0nphqx1qlmyggq58ms1phf5i03hk64wcc0a17x1m1c";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.0.1";
  };
  hashie = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1nh3arcrbz1rc1cr59qm53sdhqm137b258y8rcb4cvd3y98lwv4x";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "5.0.0";
  };
  her = {
    dependencies = ["activemodel" "faraday" "multi_json"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1xlcrr7wrq89z2r2262zksa9lql8f56xk1arx89r481a4c072zsj";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.1.1";
  };
  html-attributes-utils = {
    dependencies = ["activesupport"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "132kwasf3rn29x9zw27xfmk8fvw936bywfw9pr55aknxncvhnkjr";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.0.2";
  };
  htmlentities = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1nkklqsn8ir8wizzlakncfv42i32wc0w9hxp00hvdlgjr7376nhj";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "4.3.4";
  };
  i18n = {
    dependencies = ["concurrent-ruby"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0lbm33fpb3w06wd2231sg58dwlwgjsvym93m548ajvl6s3mfvpn7";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.14.4";
  };
  io-console = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "08d2lx42pa8jjav0lcjbzfzmw61b8imxr9041pva8xzqabrczp7h";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.7.2";
  };
  irb = {
    dependencies = ["rdoc" "reline"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "17ak21ybbprj9vg0hk8pb1r2yk9vlh50v9bdwh3qvlmpzcvljqq7";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.12.0";
  };
  jaro_winkler = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "09645h5an19zc1i7wlmixszj8xxqb2zc8qlf8dmx39bxpas1l24b";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.6.0";
  };
  json = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0nalhin1gda4v8ybk6lq8f407cgfrj6qzn234yra4ipkmlbfmal6";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.6.3";
  };
  jwt = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "16z11alz13vfc4zs5l3fk6n51n2jw9lskvc4h4prnww0y797qd87";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.7.1";
  };
  kaminari = {
    dependencies = ["activesupport" "kaminari-actionview" "kaminari-activerecord" "kaminari-core"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0gia8irryvfhcr6bsr64kpisbgdbqjsqfgrk12a11incmpwny1y4";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.2.2";
  };
  kaminari-actionview = {
    dependencies = ["actionview" "kaminari-core"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "02f9ghl3a9b5q7l079d3yzmqjwkr4jigi7sldbps992rigygcc0k";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.2.2";
  };
  kaminari-activerecord = {
    dependencies = ["activerecord" "kaminari-core"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0c148z97s1cqivzbwrak149z7kl1rdmj7dxk6rpkasimmdxsdlqd";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.2.2";
  };
  kaminari-core = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1zw3pg6kj39y7jxakbx7if59pl28lhk98fx71ks5lr3hfgn6zliv";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.2.2";
  };
  kramdown = {
    dependencies = ["rexml"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1ic14hdcqxn821dvzki99zhmcy130yhv5fqfffkcf87asv5mnbmn";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.4.0";
  };
  kramdown-parser-gfm = {
    dependencies = ["kramdown"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0a8pb3v951f4x7h968rqfsa19c8arz21zw1vaj42jza22rap8fgv";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.1.0";
  };
  language_server-protocol = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0gvb1j8xsqxms9mww01rmdl78zkd72zgxaap56bhv8j45z05hp1x";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "3.17.0.3";
  };
  lograge = {
    dependencies = ["actionpack" "activesupport" "railties" "request_store"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1qcsvh9k4c0cp6agqm9a8m4x2gg7vifryqr7yxkg2x9ph9silds2";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.14.0";
  };
  logstash-event = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1bk7fhhryjxp1klr3hq6i6srrc21wl4p980bysjp0w66z9hdr9w9";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.2.02";
  };
  logstasher = {
    dependencies = ["activesupport" "request_store"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "00hdrmyn2a0j0yzsqcz92w2wfxiprx3kk6wh46jrsax7v4494ph9";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.1.5";
  };
  loofah = {
    dependencies = ["crass" "nokogiri"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1zkjqf37v2d7s11176cb35cl83wls5gm3adnfkn2zcc61h3nxmqh";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.22.0";
  };
  mail = {
    dependencies = ["mini_mime" "net-imap" "net-pop" "net-smtp"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1bf9pysw1jfgynv692hhaycfxa8ckay1gjw5hz3madrbrynryfzc";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.8.1";
  };
  marcel = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "190n2mk8m1l708kr88fh6mip9sdsh339d2s6sgrik3sbnvz4jmhd";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.0.4";
  };
  matrix = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1h2cgkpzkh3dd0flnnwfq6f3nl2b1zff9lvqz8xs853ssv5kq23i";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.4.2";
  };
  method_source = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1igmc3sq9ay90f8xjvfnswd1dybj1s3fi0dwd53inwsvqk4h24qq";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.1.0";
  };
  mini_mime = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1vycif7pjzkr29mfk4dlqv3disc5dn0va04lkwajlpr1wkibg0c6";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.1.5";
  };
  mini_portile2 = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1q1f2sdw3y3y9mnym9dhjgsjr72sq975cfg5c4yx7gwv8nmzbvhk";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.8.7";
  };
  minitest = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "07lq26b86giy3ha3fhrywk9r1ajhc2pm2mzj657jnpnbj1i6g17a";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "5.22.3";
  };
  msgpack = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1a5adcb7bwan09mqhj3wi9ib52hmdzmqg7q08pggn3adibyn5asr";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.7.2";
  };
  multi_json = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0pb1g1y3dsiahavspyzkdy39j4q377009f6ix0bh1ag4nqw43l0z";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.15.0";
  };
  multi_xml = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0lmd4f401mvravi1i1yq7b2qjjli0yq7dfc4p1nj5nwajp7r6hyj";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.6.0";
  };
  multipart-post = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0lgyysrpl50wgcb9ahg29i4p01z0irb3p9lirygma0kkfr5dgk9x";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.3.0";
  };
  mutex_m = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1ma093ayps1m92q845hmpk0dmadicvifkbf05rpq9pifhin0rvxn";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.2.0";
  };
  net-imap = {
    dependencies = ["date" "net-protocol"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0zn7j2w0hc622ig0rslk4iy6yp3937dy9ibhyr1mwwx39n7paxaj";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.4.10";
  };
  net-pop = {
    dependencies = ["net-protocol"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1wyz41jd4zpjn0v1xsf9j778qx1vfrl24yc20cpmph8k42c4x2w4";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.1.2";
  };
  net-protocol = {
    dependencies = ["timeout"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1a32l4x73hz200cm587bc29q8q9az278syw3x6fkc9d1lv5y0wxa";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.2.2";
  };
  net-smtp = {
    dependencies = ["net-protocol"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0amlhz8fhnjfmsiqcjajip57ici2xhw089x7zqyhpk51drg43h2z";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.5.0";
  };
  nio4r = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "15iwbiij52x6jhdbl0rkcldnhfndmsy0sbnsygkr9vhskfqrp72m";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.7.1";
  };
  nokogiri = {
    dependencies = ["mini_portile2" "racc"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1vz1ychq2fhfqjgqdrx8bqkaxg5dzcgwnah00m57ydylczfy8pwk";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.16.6";
  };
  oauth2 = {
    dependencies = ["faraday" "jwt" "multi_xml" "rack" "snaky_hash" "version_gem"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1yzpaghh8kwzgmvmrlbzf36ks5s2hf34rayzw081dp2jrzprs7xj";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.0.9";
  };
  oj = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0m4vsd6i093kmyz9gckvzpnws997laldaiaf86hg5lza1ir82x7n";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "3.16.1";
  };
  omniauth = {
    dependencies = ["hashie" "rack" "rack-protection"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "15xjsxis357np7dy1lak39x1n8g8wxljb08wplw5i4gxi743zr7j";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.1.1";
  };
  omniauth-oauth2 = {
    dependencies = ["oauth2" "omniauth"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0y4y122xm8zgrxn5nnzwg6w39dnjss8pcq2ppbpx9qn7kiayky5j";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.8.0";
  };
  opentelemetry-api = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1j9c2a4wgw0jaw63qscfasw3lf3kr45q83p4mmlf0bndcq2rlgdb";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.2.5";
  };
  opentelemetry-common = {
    dependencies = ["opentelemetry-api"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1pp7i09wp5kp1npp3l8my06p7g06cglb1bi61nw8k3x5sj275kgq";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.20.1";
  };
  opentelemetry-exporter-otlp = {
    dependencies = ["google-protobuf" "googleapis-common-protos-types" "opentelemetry-api" "opentelemetry-common" "opentelemetry-sdk" "opentelemetry-semantic_conventions"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "16836gysf2cqzwx8zhx5p8vrfzmws622dc43d59y6x2cjakyw7gw";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.26.3";
  };
  opentelemetry-helpers-mysql = {
    dependencies = ["opentelemetry-api" "opentelemetry-common"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1mllrs44js9kkan1hp7716lxd7sc7cxix99amfzgzwvd08r6pcm2";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.1.0";
  };
  opentelemetry-helpers-sql-obfuscation = {
    dependencies = ["opentelemetry-common"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0cnlr3gqmd2q9wcaxhvlkxkbjvvvkp4vzcwif1j7kydw7lvz2vmw";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.1.0";
  };
  opentelemetry-instrumentation-action_pack = {
    dependencies = ["opentelemetry-api" "opentelemetry-instrumentation-base" "opentelemetry-instrumentation-rack"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "16nbkayp8jb2zkqj2rmqd4d1mz4wdf0zg6jx8b0vzkf9mxr89py5";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.9.0";
  };
  opentelemetry-instrumentation-action_view = {
    dependencies = ["opentelemetry-api" "opentelemetry-instrumentation-active_support" "opentelemetry-instrumentation-base"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0xfbqgw497k2f56f68k7zsvmrrk5jk69xhl56227dfxlw15p2z5w";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.7.0";
  };
  opentelemetry-instrumentation-active_job = {
    dependencies = ["opentelemetry-api" "opentelemetry-instrumentation-base"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "12c0qr980zr4si2ps55aj3zj84zycg3zcf16nh6mizljkmn8096s";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.7.1";
  };
  opentelemetry-instrumentation-active_model_serializers = {
    dependencies = ["opentelemetry-api" "opentelemetry-instrumentation-base"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1apgldckz3snr7869al0z18rgfplalya3x9pil3lqp4jziczhiwc";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.20.1";
  };
  opentelemetry-instrumentation-active_record = {
    dependencies = ["opentelemetry-api" "opentelemetry-instrumentation-base"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "18klcp6dz2jf31dc1dwkdy7mmfhfpggq424vbiijb442qz87h6dm";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.7.1";
  };
  opentelemetry-instrumentation-active_support = {
    dependencies = ["opentelemetry-api" "opentelemetry-instrumentation-base"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0rjajgb7sj3mrw5d79xm7q3f4mns1fc3ngasjfw10i18x0kq7283";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.5.1";
  };
  opentelemetry-instrumentation-all = {
    dependencies = ["opentelemetry-instrumentation-active_model_serializers" "opentelemetry-instrumentation-aws_sdk" "opentelemetry-instrumentation-bunny" "opentelemetry-instrumentation-concurrent_ruby" "opentelemetry-instrumentation-dalli" "opentelemetry-instrumentation-delayed_job" "opentelemetry-instrumentation-ethon" "opentelemetry-instrumentation-excon" "opentelemetry-instrumentation-faraday" "opentelemetry-instrumentation-grape" "opentelemetry-instrumentation-graphql" "opentelemetry-instrumentation-gruf" "opentelemetry-instrumentation-http" "opentelemetry-instrumentation-http_client" "opentelemetry-instrumentation-koala" "opentelemetry-instrumentation-lmdb" "opentelemetry-instrumentation-mongo" "opentelemetry-instrumentation-mysql2" "opentelemetry-instrumentation-net_http" "opentelemetry-instrumentation-pg" "opentelemetry-instrumentation-que" "opentelemetry-instrumentation-racecar" "opentelemetry-instrumentation-rack" "opentelemetry-instrumentation-rails" "opentelemetry-instrumentation-rake" "opentelemetry-instrumentation-rdkafka" "opentelemetry-instrumentation-redis" "opentelemetry-instrumentation-resque" "opentelemetry-instrumentation-restclient" "opentelemetry-instrumentation-ruby_kafka" "opentelemetry-instrumentation-sidekiq" "opentelemetry-instrumentation-sinatra" "opentelemetry-instrumentation-trilogy"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "141ycarxd3gkki34y9x9hfziv33lfwzinz1xh2g90z9q8ymrmja2";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.60.0";
  };
  opentelemetry-instrumentation-aws_sdk = {
    dependencies = ["opentelemetry-api" "opentelemetry-instrumentation-base"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1khc17rkwbqcma9qa1cm68brhcq1gjwnvcb9rn6x1x4zql9qssj9";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.5.1";
  };
  opentelemetry-instrumentation-base = {
    dependencies = ["opentelemetry-api" "opentelemetry-registry"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0pv064ksiynin8hzvljkwm5vlkgr8kk6g3qqpiwcik860i7l677n";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.22.3";
  };
  opentelemetry-instrumentation-bunny = {
    dependencies = ["opentelemetry-api" "opentelemetry-instrumentation-base"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "16y7w6ncx4g6pnxjxkpp68fgbhk3k7gn8gyrp0vcrwwrms6p3rjb";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.21.2";
  };
  opentelemetry-instrumentation-concurrent_ruby = {
    dependencies = ["opentelemetry-api" "opentelemetry-instrumentation-base"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0rgxicgglpl30i9h29lzrnvf2hcl5wbi60l5ydy06zrw2dn5ya6c";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.21.2";
  };
  opentelemetry-instrumentation-dalli = {
    dependencies = ["opentelemetry-api" "opentelemetry-common" "opentelemetry-instrumentation-base"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "00a77n2ks4qac9qpgycqq5p9knxflj0qij3yf968p04lfdxh5bx8";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.25.0";
  };
  opentelemetry-instrumentation-delayed_job = {
    dependencies = ["opentelemetry-api" "opentelemetry-instrumentation-base"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0ka03iik88h1blmwvfsy9c05qgsnx6i9fzn9jy8lygypmykfk1wm";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.22.1";
  };
  opentelemetry-instrumentation-ethon = {
    dependencies = ["opentelemetry-api" "opentelemetry-common" "opentelemetry-instrumentation-base"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "16g65c4l4i52hchm30i5ypswm39qzd7bbnfgrp3pny0yhsxp30qp";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.21.3";
  };
  opentelemetry-instrumentation-excon = {
    dependencies = ["opentelemetry-api" "opentelemetry-common" "opentelemetry-instrumentation-base"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "11vyvh5l176vqz246hgl837l0qqn13dcisz98x4i2jivassyln7w";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.22.0";
  };
  opentelemetry-instrumentation-faraday = {
    dependencies = ["opentelemetry-api" "opentelemetry-common" "opentelemetry-instrumentation-base"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0a5zpsiv9hyscsmb3z876v87ij48jgrz1h0510dykvsr3wj2ajad";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.24.1";
  };
  opentelemetry-instrumentation-grape = {
    dependencies = ["opentelemetry-api" "opentelemetry-instrumentation-base" "opentelemetry-instrumentation-rack"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0ws105sbpfq795bzhnvz9wz0wcd194g1y7j6xbzmr83wzr0xaw6j";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.1.6";
  };
  opentelemetry-instrumentation-graphql = {
    dependencies = ["opentelemetry-api" "opentelemetry-instrumentation-base"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1by9zxv0nwfp2amqpqkz1gfdx839pswrlzl45lqlj25lj27m5nf8";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.28.1";
  };
  opentelemetry-instrumentation-gruf = {
    dependencies = ["opentelemetry-api" "opentelemetry-instrumentation-base"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1ricwwfws1p3m5dn4zylhbxg0s1mn70fbp4c5wns5wmjaljv5y8q";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.2.0";
  };
  opentelemetry-instrumentation-http = {
    dependencies = ["opentelemetry-api" "opentelemetry-instrumentation-base"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0gwyfw6v1jdi3fb5k3smjizh28k4q8bihg95i80wm4144hm8sm0w";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.23.2";
  };
  opentelemetry-instrumentation-http_client = {
    dependencies = ["opentelemetry-api" "opentelemetry-common" "opentelemetry-instrumentation-base"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0y41n1dhqfqmcqrka3zk00673jynlsidm8i5ibckjamah4svir1l";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.22.3";
  };
  opentelemetry-instrumentation-koala = {
    dependencies = ["opentelemetry-api" "opentelemetry-common" "opentelemetry-instrumentation-base"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1yqy0gix788xn8m2d4h7530w1bwjai62dw8ssxwsqxvm2clr61pi";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.20.2";
  };
  opentelemetry-instrumentation-lmdb = {
    dependencies = ["opentelemetry-api" "opentelemetry-instrumentation-base"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1g6lv7wydvck6y605jbfdk33nh08cwahq5ygyjslwzca77kcli5q";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.22.1";
  };
  opentelemetry-instrumentation-mongo = {
    dependencies = ["opentelemetry-api" "opentelemetry-instrumentation-base"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1c0hmlzglqnjxf87rc7ar5zmvk6j89dwx9k23imzgqkaszynks0i";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.22.2";
  };
  opentelemetry-instrumentation-mysql2 = {
    dependencies = ["opentelemetry-api" "opentelemetry-helpers-mysql" "opentelemetry-helpers-sql-obfuscation" "opentelemetry-instrumentation-base"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1mkgs14dnibsn41qb0vf9a39c6drkj32lma43y7ng8qfb873mf5w";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.27.0";
  };
  opentelemetry-instrumentation-net_http = {
    dependencies = ["opentelemetry-api" "opentelemetry-common" "opentelemetry-instrumentation-base"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1klq4rpn803byrz7z1mxsj81qg7kpl67nj5sqqw41msnwkkbay18";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.22.4";
  };
  opentelemetry-instrumentation-pg = {
    dependencies = ["opentelemetry-api" "opentelemetry-helpers-sql-obfuscation" "opentelemetry-instrumentation-base"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "01ia23kfvdwv1f7p7frvwxj8lqcvz26klqh90h7bdzj4bj1x261r";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.27.1";
  };
  opentelemetry-instrumentation-que = {
    dependencies = ["opentelemetry-api" "opentelemetry-instrumentation-base"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1kva2zzxm3v0l58a286p1a1xy4xmy31y89gyshlch87642x4hh5b";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.8.0";
  };
  opentelemetry-instrumentation-racecar = {
    dependencies = ["opentelemetry-api" "opentelemetry-instrumentation-base"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0imggg8pi9a08wbs2kvd975h9lw82p0danpnqwk4hzxfzycphyr4";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.3.1";
  };
  opentelemetry-instrumentation-rack = {
    dependencies = ["opentelemetry-api" "opentelemetry-common" "opentelemetry-instrumentation-base"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "066nl49pbs4rbwxiscpw59scgcb866xsrj8214dlznpm9d424s0j";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.24.1";
  };
  opentelemetry-instrumentation-rails = {
    dependencies = ["opentelemetry-api" "opentelemetry-instrumentation-action_pack" "opentelemetry-instrumentation-action_view" "opentelemetry-instrumentation-active_job" "opentelemetry-instrumentation-active_record" "opentelemetry-instrumentation-active_support" "opentelemetry-instrumentation-base"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0dwwbgpfxik43j55ig04j826jhm3x414pwxjjs5cdcs29whd4azy";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.30.0";
  };
  opentelemetry-instrumentation-rake = {
    dependencies = ["opentelemetry-api" "opentelemetry-instrumentation-base"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0y4jxnbcdl0nz9xsp61kf4lhd4g1aawbax77gxlv3jd1jbsinvn4";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.2.1";
  };
  opentelemetry-instrumentation-rdkafka = {
    dependencies = ["opentelemetry-api" "opentelemetry-common" "opentelemetry-instrumentation-base"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1nzs4bw5fmbid58m839ac61lapyl7dqmzjfanza7jcg733ga6mc9";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.4.3";
  };
  opentelemetry-instrumentation-redis = {
    dependencies = ["opentelemetry-api" "opentelemetry-common" "opentelemetry-instrumentation-base"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "04i1zlplsfzrd5rklpf216hi7wdflb79ws548w0vn20h3iprlr1c";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.25.3";
  };
  opentelemetry-instrumentation-resque = {
    dependencies = ["opentelemetry-api" "opentelemetry-instrumentation-base"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "06pyylrliycnbyqyzccqmc4j113sq2r7lrxljx8ff536jiij1l1c";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.5.1";
  };
  opentelemetry-instrumentation-restclient = {
    dependencies = ["opentelemetry-api" "opentelemetry-common" "opentelemetry-instrumentation-base"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0yvi9lhm0mpp151zx9hl97cjf22mv639w7g7d05qnq2f6vl6yy20";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.22.3";
  };
  opentelemetry-instrumentation-ruby_kafka = {
    dependencies = ["opentelemetry-api" "opentelemetry-instrumentation-base"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1bggmrs34y13v343h0z4gcd2rhpr96rrwakjz0k4y8syzijxvwv8";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.21.0";
  };
  opentelemetry-instrumentation-sidekiq = {
    dependencies = ["opentelemetry-api" "opentelemetry-common" "opentelemetry-instrumentation-base"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1k4n10kp0rvbglh494ca3l5rf0psccsgvp5ad46j35bai452snlc";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.25.2";
  };
  opentelemetry-instrumentation-sinatra = {
    dependencies = ["opentelemetry-api" "opentelemetry-common" "opentelemetry-instrumentation-base" "opentelemetry-instrumentation-rack"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1m7x3hcjgh07mlh6m3d605yr6am27wggid24qc6g2lgsksml4zqd";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.23.2";
  };
  opentelemetry-instrumentation-trilogy = {
    dependencies = ["opentelemetry-api" "opentelemetry-helpers-mysql" "opentelemetry-helpers-sql-obfuscation" "opentelemetry-instrumentation-base" "opentelemetry-semantic_conventions"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0g477ki49jsk8xsj2v24m4n3c5lv0kczb4xxpyk11hn49pxdvzfr";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.59.2";
  };
  opentelemetry-registry = {
    dependencies = ["opentelemetry-api"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1pw87n9vpv40hf7f6gyl2vvbl11hzdkv4psbbv3x23jvccs8593k";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.3.1";
  };
  opentelemetry-sdk = {
    dependencies = ["opentelemetry-api" "opentelemetry-common" "opentelemetry-registry" "opentelemetry-semantic_conventions"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1ajf9igx63r6r2ds0f3hxd18iragvr88k2k9kzvamp1jkdna6gsi";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.4.1";
  };
  opentelemetry-semantic_conventions = {
    dependencies = ["opentelemetry-api"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0xhv5fwwgjj2k8ksprpg1nm5v8k3w6gyw4wiq2k08q3kf484rlhk";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.10.0";
  };
  pagy = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0fxcngkhrgi48ss4l6gaf8wrxm08jmnz32m49jx13jnf0k0yy1h6";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "7.0.11";
  };
  parallel = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0jcc512l38c0c163ni3jgskvq1vc3mr8ly5pvjijzwvfml9lf597";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.23.0";
  };
  parser = {
    dependencies = ["ast" "racc"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1swigds85jddb5gshll1g8lkmbcgbcp9bi1d4nigwvxki8smys0h";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "3.2.2.3";
  };
  pg = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0pfj771p5a29yyyw58qacks464sl86d5m3jxjl5rlqqw2m3v5xq4";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.5.4";
  };
  plek = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1zb91myghjwf72y78p91kc96yp5wya3i8p2nnvr0l8dra8hzli51";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "5.1.0";
  };
  prometheus_exporter = {
    dependencies = ["webrick"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "10bh62y5k10mqch0vb6hdkywhivjlxilkv023n6kaf97viiz3989";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.1.0";
  };
  pry = {
    dependencies = ["coderay" "method_source"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0k9kqkd9nps1w1r1rb7wjr31hqzkka2bhi8b518x78dcxppm9zn4";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.14.2";
  };
  pry-byebug = {
    dependencies = ["byebug" "pry"];
    groups = ["development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1y41al94ks07166qbp2200yzyr5y60hm7xaiw4lxpgsm4b1pbyf8";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "3.10.1";
  };
  pry-rails = {
    dependencies = ["pry"];
    groups = ["development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1cf4ii53w2hdh7fn8vhqpzkymmchjbwij4l3m7s6fsxvb9bn51j6";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.3.9";
  };
  psych = {
    dependencies = ["stringio"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0s5383m6004q76xm3lb732bp4sjzb6mxb6rbgn129gy2izsj4wrk";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "5.1.2";
  };
  public_suffix = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1bni4qjrsh2q49pnmmd6if4iv3ak36bd2cckrs6npl111n769k9m";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "5.0.4";
  };
  puma = {
    dependencies = ["nio4r"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0i2vaww6qcazj0ywva1plmjnj6rk23b01szswc5jhcq7s2cikd1y";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "6.4.2";
  };
  pundit = {
    dependencies = ["activesupport"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "10diasjqi1g7s19ns14sldia4wl4c0z1m4pva66q4y2jqvks4qjw";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.3.1";
  };
  raabro = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "10m8bln9d00dwzjil1k42i5r7l82x25ysbi45fwyv4932zsrzynl";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.4.0";
  };
  racc = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "021s7maw0c4d9a6s07vbmllrzqsj2sgmrwimlh8ffkvwqdjrld09";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.8.0";
  };
  rack = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0hj0rkw2z9r1lcg2wlrcld2n3phwrcgqcp7qd1g9a7hwgalh2qzx";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.2.9";
  };
  rack-protection = {
    dependencies = ["rack"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0xsz78hccgza144n37bfisdkzpr2c8m0xl6rnlzgxdbsm1zrkg7r";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "3.1.0";
  };
  rack-proxy = {
    dependencies = ["rack"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "12jw7401j543fj8cc83lmw72d8k6bxvkp9rvbifi88hh01blnsj4";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.7.7";
  };
  rack-session = {
    dependencies = ["rack"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0xhxhlsz6shh8nm44jsmd9276zcnyzii364vhcvf0k8b8bjia8d0";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.0.2";
  };
  rack-test = {
    dependencies = ["rack"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1ysx29gk9k14a14zsp5a8czys140wacvp91fja8xcja0j1hzqq8c";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.1.0";
  };
  rackup = {
    dependencies = ["rack" "webrick"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1wbr03334ba9ilcq25wh9913xciwj0j117zs60vsqm0zgwdkwpp9";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.0.0";
  };
  rails = {
    dependencies = ["actioncable" "actionmailbox" "actionmailer" "actionpack" "actiontext" "actionview" "activejob" "activemodel" "activerecord" "activestorage" "activesupport" "railties"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "185zq5r9g56sfks852992bm0xf2vm9569jyiz5jyww3vx1jply1d";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "7.1.3.2";
  };
  rails-controller-testing = {
    dependencies = ["actionpack" "actionview" "activesupport"];
    groups = ["test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "151f303jcvs8s149mhx2g5mn67487x0blrf9dzl76q1nb7dlh53l";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.0.5";
  };
  rails-dom-testing = {
    dependencies = ["activesupport" "minitest" "nokogiri"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0fx9dx1ag0s1lr6lfr34lbx5i1bvn3bhyf3w3mx6h7yz90p725g5";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.2.0";
  };
  rails-html-sanitizer = {
    dependencies = ["loofah" "nokogiri"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1pm4z853nyz1bhhqr7fzl44alnx4bjachcr6rh6qjj375sfz3sc6";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.6.0";
  };
  railties = {
    dependencies = ["actionpack" "activesupport" "irb" "rackup" "rake" "thor" "zeitwerk"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0435sfvhhrd4b2ic9b4c2df3i1snryidx7ry9km4805rpxfdbz2r";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "7.1.3.2";
  };
  rainbow = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0smwg4mii0fm38pyb5fddbmrdpifwv22zv3d3px2xx497am93503";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "3.1.1";
  };
  rake = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "17850wcwkgi30p7yqh60960ypn7yibacjjha0av78zaxwvd3ijs6";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "13.2.1";
  };
  rbs = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0dgj5n7rj83981fvrhswfwsh88x42p7r00nvd80hkxmdcjvda2h6";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.8.4";
  };
  rdoc = {
    dependencies = ["psych"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0ib3cnf4yllvw070gr4bz94sbmqx3haqc5f846fsvdcs494vgxrr";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "6.6.3.1";
  };
  redis = {
    dependencies = ["redis-client"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1n7k4sgx5vzsigp8c15flz4fclqy4j2a33vim7b2c2w5jyjhwxrv";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "5.0.8";
  };
  redis-client = {
    dependencies = ["connection_pool"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1afyfxg5kxmrxsbsvqvk9zmqdi85wa0v164a3x3dwb3x03plp06y";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.19.1";
  };
  regexp_parser = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "136br91alxdwh1s85z912dwz23qlhm212vy6i3wkinz3z8mkxxl3";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.8.1";
  };
  reline = {
    dependencies = ["io-console"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0d90nhsqvzp576dsz622fcz0r4zj9hvqlvb6y00f20zx3mx78iic";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.5.3";
  };
  request_store = {
    dependencies = ["rack"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0kd4w7aa0sbk59b19s39pwhd636r7fjamrqalixsw5d53hs4sb1d";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.6.0";
  };
  responders = {
    dependencies = ["actionpack" "railties"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "06ilkbbwvc8d0vppf8ywn1f79ypyymlb9krrhqv4g0q215zaiwlj";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "3.1.1";
  };
  reverse_markdown = {
    dependencies = ["nokogiri"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0087vhw5ik50lxvddicns01clkx800fk5v5qnrvi3b42nrk6885j";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.1.1";
  };
  rexml = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "05i8518ay14kjbma550mv0jm8a6di8yp5phzrd8rj44z9qnrlrp0";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "3.2.6";
  };
  rinku = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0zcdha17s1wzxyc5814j6319wqg33jbn58pg6wmxpws36476fq4b";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.0.6";
  };
  rouge = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1zd1pdldi6h8x27dqim7cy8m69xr01aw5c8k1zhkz497n4np6wgk";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "4.2.1";
  };
  routing-filter = {
    dependencies = ["actionpack" "activesupport"];
    groups = ["default"];
    platforms = [];
    source = {
      fetchSubmodules = false;
      rev = "3efb9d3cf4b32c976295bb4ed3473c0cce1c1241";
      sha256 = "0r61lf71h76yhfwl3b1kycwrk192n2nhqjz25m6fvp3y6pdf4py8";
      type = "git";
      url = "https://github.com/trade-tariff/routing-filter.git";
    };
    targets = [];
    version = "1.0.0";
  };
  rspec = {
    dependencies = ["rspec-core" "rspec-expectations" "rspec-mocks"];
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "171rc90vcgjl8p1bdrqa92ymrj8a87qf6w20x05xq29mljcigi6c";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "3.12.0";
  };
  rspec-core = {
    dependencies = ["rspec-support"];
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0l95bnjxdabrn79hwdhn2q1n7mn26pj7y1w5660v5qi81x458nqm";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "3.12.2";
  };
  rspec-expectations = {
    dependencies = ["diff-lcs" "rspec-support"];
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "05j44jfqlv7j2rpxb5vqzf9hfv7w8ba46wwgxwcwd8p0wzi1hg89";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "3.12.3";
  };
  rspec-mocks = {
    dependencies = ["diff-lcs" "rspec-support"];
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1gq7gviwpck7fhp4y5ibljljvxgjklza18j62qf6zkm2icaa8lfy";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "3.12.6";
  };
  rspec-rails = {
    dependencies = ["actionpack" "activesupport" "railties" "rspec-core" "rspec-expectations" "rspec-mocks" "rspec-support"];
    groups = ["test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "086qdyz7c4s5dslm6j06mq7j4jmj958whc3yinhabnqqmz7i463d";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "6.0.3";
  };
  rspec-support = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1ky86j3ksi26ng9ybd7j0qsdf1lpr8mzrmn98yy9gzv801fvhsgr";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "3.12.1";
  };
  rspec_junit_formatter = {
    dependencies = ["rspec-core"];
    groups = ["test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "059bnq1gcwl9g93cqf13zpz38zk7jxaa43anzz06qkmfwrsfdpa0";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.6.0";
  };
  rubocop = {
    dependencies = ["json" "language_server-protocol" "parallel" "parser" "rainbow" "regexp_parser" "rexml" "rubocop-ast" "ruby-progressbar" "unicode-display_width"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "17c94wl2abqzf4fj469mdxzap1sd3410x421nl6mh2w49jsgvpki";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.55.0";
  };
  rubocop-ast = {
    dependencies = ["parser"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "188bs225kkhrb17dsf3likdahs2p1i1sqn0pr3pvlx50g6r2mnni";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.29.0";
  };
  rubocop-capybara = {
    dependencies = ["rubocop"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "01fn05a87g009ch1sh00abdmgjab87i995msap26vxq1a5smdck6";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.18.0";
  };
  rubocop-factory_bot = {
    dependencies = ["rubocop"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0kqchl8f67k2g56sq2h1sm2wb6br5gi47s877hlz94g5086f77n1";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.23.1";
  };
  rubocop-govuk = {
    dependencies = ["rubocop" "rubocop-ast" "rubocop-rails" "rubocop-rake" "rubocop-rspec"];
    groups = ["development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0dxg7j28qbpr6a5bz99gv1scxjriv1y6ni5ng8xg0qlszl68bwqz";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "4.12.0";
  };
  rubocop-rails = {
    dependencies = ["activesupport" "rack" "rubocop"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "05r46ds0dm44fb4p67hbz721zck8mdwblzssz2y25yh075hvs36j";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.20.2";
  };
  rubocop-rake = {
    dependencies = ["rubocop"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1nyq07sfb3vf3ykc6j2d5yq824lzq1asb474yka36jxgi4hz5djn";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.6.0";
  };
  rubocop-rspec = {
    dependencies = ["rubocop" "rubocop-capybara" "rubocop-factory_bot"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "00rsflhijcr0q838fgbdmk7knm5kcjpimn6x0k9qmiw15hi96x1d";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.22.0";
  };
  ruby-progressbar = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0cwvyb7j47m7wihpfaq7rc47zwwx9k4v7iqd9s1xch5nm53rrz40";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.13.0";
  };
  ruby2_keywords = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1vz322p8n39hz3b4a9gkmz9y7a5jaz41zrm2ywf31dvkqm03glgz";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.0.5";
  };
  rufus-scheduler = {
    dependencies = ["fugit"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "14lr8c2sswn0sisvrfi4448pmr34za279k3zlxgh581rl1y0gjjz";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "3.9.1";
  };
  sanitize = {
    dependencies = ["crass" "nokogiri"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0wsw05y0h1ln3x2kvcw26fs9ivryb4xbjrb4hsk2pishkhydkz4j";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "6.1.0";
  };
  semantic_range = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1dlp97vg95plrsaaqj7x8l7z9vsjbhnqk4rw1l30gy26lmxpfrih";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "3.0.0";
  };
  sentry-rails = {
    dependencies = ["railties" "sentry-ruby"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0ncl8br0k6fas4n6c4xw4wr59kq5s2liqn1s4790m73k5p272xq1";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "5.17.3";
  };
  sentry-ruby = {
    dependencies = ["bigdecimal" "concurrent-ruby"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1z5v5zzasy04hbgxbj9n8bb39ayllvps3snfgbc5rydh1d5ilyb1";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "5.17.3";
  };
  shoulda-matchers = {
    dependencies = ["activesupport"];
    groups = ["test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1p83ca48h812h5gksw2q0x5289jsc4c417f8s6w9d4a12jzw86zi";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "6.1.0";
  };
  shrine = {
    dependencies = ["content_disposition" "down"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0nyzkfs1bd8hb2jj5xxwdgsx2ph8v38hs9k1fb30hsqa77vyy9lb";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "3.5.0";
  };
  sidekiq = {
    dependencies = ["concurrent-ruby" "connection_pool" "rack" "redis-client"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "057vw807x98r4xmhyv2m2rxa8qqxr7ysn7asp5hmdvn9sa9kkm3c";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "7.2.1";
  };
  sidekiq-scheduler = {
    dependencies = ["rufus-scheduler" "sidekiq" "tilt"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0p5jjs3x2pa2fy494xs39xbq642pri13809dcr1l3hjsm56qvp1h";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "5.0.3";
  };
  simple_form = {
    dependencies = ["actionpack" "activemodel"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0070d1dvj3m908p45macjxmi8n92cwdgkwkd1jbcml6ynlp4p2v2";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "5.3.0";
  };
  simplecov = {
    dependencies = ["docile" "simplecov-html" "simplecov_json_formatter"];
    groups = ["test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "198kcbrjxhhzca19yrdcd6jjj9sb51aaic3b0sc3pwjghg3j49py";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.22.0";
  };
  simplecov-html = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0yx01bxa8pbf9ip4hagqkp5m0mqfnwnw2xk8kjraiywz4lrss6jb";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.12.3";
  };
  simplecov_json_formatter = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0a5l0733hj7sk51j81ykfmlk2vd5vaijlq9d5fn165yyx3xii52j";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.1.4";
  };
  snaky_hash = {
    dependencies = ["hashie" "version_gem"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0cfwvdcr46pk0c7m5aw2w3izbrp1iba0q7l21r37mzpwaz0pxj0s";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.0.1";
  };
  solargraph = {
    dependencies = ["backport" "benchmark" "diff-lcs" "e2mmap" "jaro_winkler" "kramdown" "kramdown-parser-gfm" "parser" "rbs" "reverse_markdown" "rubocop" "thor" "tilt" "yard"];
    groups = ["development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0qbjgsrlrwvbywzi0shf3nmfhb52y5fmp9al9nk7c4qqwxyhz397";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.50.0";
  };
  sprockets = {
    dependencies = ["concurrent-ruby" "rack"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "15rzfzd9dca4v0mr0bbhsbwhygl0k9l24iqqlx0fijig5zfi66wm";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "4.2.1";
  };
  sprockets-rails = {
    dependencies = ["actionpack" "activesupport" "sprockets"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1b9i14qb27zs56hlcc2hf139l0ghbqnjpmfi0054dxycaxvk5min";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "3.4.2";
  };
  statsd-ruby = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "028136c463nbravckxb1qi5c5nnv9r6vh2cyhiry423lac4xz79n";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.5.0";
  };
  stringio = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "063psvsn1aq6digpznxfranhcpmi0sdv2jhra5g0459sw0x2dxn1";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "3.1.0";
  };
  thor = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1vq1fjp45az9hfp6fxljhdrkv75cvbab1jfrwcw738pnsiqk8zps";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.3.1";
  };
  tilt = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0bmjgbv8158klwp2r3klxjwaj93nh1sbl4xvj9wsha0ic478avz7";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.2.0";
  };
  timeout = {
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "16mvvsmx90023wrhf8dxc1lpqh0m8alk65shb7xcya6a9gflw7vg";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.4.1";
  };
  tzinfo = {
    dependencies = ["concurrent-ruby"];
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "16w2g84dzaf3z13gxyzlzbf748kylk5bdgg3n1ipvkvvqy685bwd";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.0.6";
  };
  unicode-display_width = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1gi82k102q7bkmfi7ggn9ciypn897ylln1jk9q67kjhr39fj043a";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.4.2";
  };
  version_gem = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0q6zs0wgcrql9671fw6lmbvgh155snaak4fia24iji5wk9klpfh7";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.1.3";
  };
  view_component = {
    dependencies = ["activesupport" "concurrent-ruby" "method_source"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1zy51z0whkm3fdpsbi8v4j8h5h3ia1zkc2j28amiznpqqvfc7539";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "3.11.0";
  };
  warden = {
    dependencies = ["rack"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1l7gl7vms023w4clg02pm4ky9j12la2vzsixi2xrv9imbn44ys26";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.2.9";
  };
  warden-oauth2 = {
    dependencies = ["warden"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1z9154lvzrnnfjbjkmirh4n811nygp6pm2fa6ikr7y1ysa4zv3cz";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.0.1";
  };
  webmock = {
    dependencies = ["addressable" "crack" "hashdiff"];
    groups = ["test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0vfispr7wd2p1fs9ckn1qnby1yyp4i1dl7qz8n482iw977iyxrza";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "3.19.1";
  };
  webpacker = {
    dependencies = ["activesupport" "rack-proxy" "railties" "semantic_range"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0fh4vijqiq1h7w28llk67y9csc0m4wkdivrsl4fsxg279v6j5z3i";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "5.4.4";
  };
  webrick = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "13qm7s0gr2pmfcl7dxrmq38asaza4w0i2n9my4yzs499j731wh8r";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.8.1";
  };
  websocket-driver = {
    dependencies = ["websocket-extensions"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1nyh873w4lvahcl8kzbjfca26656d5c6z3md4sbqg5y1gfz0157n";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.7.6";
  };
  websocket-extensions = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0hc2g9qps8lmhibl5baa91b4qx8wqw872rgwagml78ydj8qacsqw";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.1.5";
  };
  xpath = {
    dependencies = ["nokogiri"];
    groups = ["default" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0bh8lk9hvlpn7vmi6h4hkcwjzvs2y0cmkk3yjjdr8fxvj6fsgzbd";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "3.2.0";
  };
  yard = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "14k9lb9a60r9z2zcqg08by9iljrrgjxdkbd91gw17rkqkqwi1sd6";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.9.37";
  };
  zeitwerk = {
    groups = ["default" "development" "test"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1m67qmsak3x8ixs8rb971azl3l7wapri65pmbf5z886h46q63f1d";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.6.13";
  };
}