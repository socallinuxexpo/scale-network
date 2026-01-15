{
  lib,
  config,
  ...
}:
let
  cfg = config.scale-network.users.erikreinert;
  inherit (lib.modules)
    mkIf
    ;

  inherit (lib.options)
    mkEnableOption
    ;
in
{
  options.scale-network.users.erikreinert.enable = mkEnableOption "user erikreinert";

  config = mkIf cfg.enable {
    users.users = {
      erikreinert = {
        isNormalUser = true;
        uid = 2014;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDEoozwkEkRw4BtbKU8+boF6ixoOiE20cpbi1EXHJqnT3unSF2Jb7nqV+ywVVtRAGMtK5mV8j9smjx0A5/yCJkpNy1hamZC7Xx5WHUWn/M6+Xk6OkHSW9DcCPli+RgiL5ESHVhRJWpC9Vp+afXJBrzXzu1mPcObP9cWiMPCy67pVp1Rh/r7leUdzjAORQFxmynjdh8WleguNU7F1IfaGm4JlSdUxQTSFbJJst03gQSQdHoUxtqvBeEAyj1LhN6t7eY1sDSQpflafoVGYznE3GrPn39qATgT1fCr/ELKRqe+j6d7XEJdcGClcAF23lrZhTiMTkrTortHbi/BGV4jDIzT2OyFrXXjZT8ZBl1z7Bm9h9i0JaVjLdUnGJH8Sc/pBt2PWOM9EOaFuhp8uc2LbjqgCeK1Y/zysbV7U6Qz4ChCMLTm7ccPnXctUc69McLcj5q1Jy28xZOED6biUqg9kSZvLQ84Dlrxy2/MjSwINfFBqEP3AhCRhrmxrtPHBM0BpYHAK7xyJyaHPOXVf0MjhH3jLZ+TKlXbXzNoAvh0jrG6oJnprDCeX9OKPOmsxYZMeuHMswAIh6MAibOlQmDfLGGB5cCCSjc0E05I5hxF1U24neZcg8Yk/kbanoRKwPzJAtR+GVdQ0wJJnTQIpTIi6DVsKniHTC5oA/4biLDd6yPpDw=="
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCX18nJOiAo6kK9wLWJrxNVYLHlFkMXdJUbD7MhfsjBryTM8SCSDh0HD24HnCeGkFBbapeXOSFxCmnedLXRE6StecBIJZ/jOs2TJRxay6kmtK2eobfavvKB8ZRrULtoFALcduNHIph82q2TT16WdCAO7jbDWpYtWgMz88J/6cYNPMNGEwq1NSocQ+BQU/6RplfOOUNiqPIigo84cW4x1QmX3a5g/mJ2J2Q8ZSdmC83nUMh6Si52qd35+3ZE27PMrt/St4n/zG6oSDlomFaVkRzkrJt2JlNUwA2ZZm3Sa+BF17SZMkAULMr7UNXdcky/3Ys71yxIVi8TGFa4bwZsw720dbETfnQoA/R4frDFIY+5LoVbcGdOryDQ0lbLhjlysPVe5fyeIN/xRu0mnfAWonr2qZKsbPf0vS/zTGE9c7Z2dtbkxdsi6Ym0H23UQUoh986Wh6hpCGUr2ru/3rFwHXPgOhj6jWjqopzYhyV7tFGljt/u/9TbyNO5pIRRCvRTkFke3K83itmC3L110xZg/d4jloeCJqW/Uf+7kme+4fkYdXx7EPpxnRRMOIYd5eB757tY2zgsqIkodCaeaPk+opUTQsxKz6AuIQfzMMEOqAeiryS+I3uJoYqs0NtlUkMqnsYYZHz04XSpK1Rlbs7gqitfVWdcFJ5kSZzcIqaqPGwStQ== temp"
        ];
      };
    };
  };
}
