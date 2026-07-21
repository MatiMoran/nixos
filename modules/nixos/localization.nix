{ lib, ... }:

{
  config.nixosModules = lib.mkAfter [
    ({ ... }: {
      time.timeZone = "America/Argentina/Buenos_Aires";
      i18n.defaultLocale = "en_US.UTF-8";
      i18n.extraLocaleSettings = {
        LC_MEASUREMENT = "es_AR.UTF-8";
        LC_TIME = "es_AR.UTF-8";
      };
    })
  ];
}
