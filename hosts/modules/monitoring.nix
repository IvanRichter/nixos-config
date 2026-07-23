{
  services.below = {
    enable = true;
    compression.enable = true;

    retention = {
      size = 20 * 1024 * 1024 * 1024; # 20 GiB
      time = 14 * 24 * 60 * 60; # 14 days
    };
  };
}
