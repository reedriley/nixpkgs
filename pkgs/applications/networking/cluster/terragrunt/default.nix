{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "terragrunt";
  version = "0.35.20";

  src = fetchFromGitHub {
    owner = "gruntwork-io";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-iSD036rDZvvMUGMHnjKh69eVUVQakI8muSCCq2ytODM=";
  };

  vendorSha256 = "sha256-tNgEepKqwiqXhmoRCIEg7VJw7Y0TGt+R+6dZzd8aECg=";

  doCheck = false;

  ldflags = [ "-s" "-w" "-X main.VERSION=v${version}" ];

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    $out/bin/terragrunt --help
    $out/bin/terragrunt --version | grep "v${version}"
    runHook postInstallCheck
  '';

  meta = with lib; {
    homepage = "https://terragrunt.gruntwork.io";
    changelog = "https://github.com/gruntwork-io/terragrunt/releases/tag/v${version}";
    description = "A thin wrapper for Terraform that supports locking for Terraform state and enforces best practices";
    license = licenses.mit;
    maintainers = with maintainers; [ jk ];
  };
}
