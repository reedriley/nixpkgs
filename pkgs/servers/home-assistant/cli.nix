{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchpatch,
  python3,
  installShellFiles,
}:

python3.pkgs.buildPythonApplication (finalAttrs: {
  pname = "homeassistant-cli";
  version = "1.0.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "home-assistant-ecosystem";
    repo = "home-assistant-cli";
    tag = finalAttrs.version;
    hash = "sha256-LF6JXELAP3Mvta3RuDUs4UiQ7ptNFh0vZmPh3ICJFRY=";
  };

  # asyncio.get_event_loop() raises RuntimeError on Python 3.14 (implicit loop
  # creation removed), breaking every `hass-cli raw ws` call. Fixed upstream four
  # days after the 1.0.0 tag; 1.0.1 exists in the tree but was never released.
  # Drop this once a release carries it.
  patches = [
    (fetchpatch {
      name = "replace-asyncio-get-event-loop.patch";
      url = "https://github.com/home-assistant-ecosystem/home-assistant-cli/commit/184cc48b4b9e4c6df8817e05fa3258b3b52caa91.patch";
      hash = "sha256-xGXfrvwP3+Wva0S7Sv9eRCt3n5PaKLQxmdHPYp1Ew8M=";
    })
  ];

  pythonRelaxDeps = true;

  build-system = with python3.pkgs; [ poetry-core ];

  dependencies = with python3.pkgs; [
    aiohttp
    click
    click-log
    dateparser
    jinja2
    jsonpath-ng
    netdisco
    regex
    requests
    ruamel-yaml
    tabulate
  ];

  postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    installShellCompletion --cmd hass-cli \
      --bash <(_HASS_CLI_COMPLETE=bash_source $out/bin/hass-cli) \
      --fish <(_HASS_CLI_COMPLETE=fish_source $out/bin/hass-cli) \
      --zsh <(_HASS_CLI_COMPLETE=zsh_source $out/bin/hass-cli)
  '';

  nativeBuildInputs = [ installShellFiles ];

  nativeCheckInputs = with python3.pkgs; [
    pytestCheckHook
    requests-mock
  ];

  pythonImportsCheck = [ "homeassistant_cli" ];

  meta = {
    description = "Command-line tool for Home Assistant";
    mainProgram = "hass-cli";
    homepage = "https://github.com/home-assistant-ecosystem/home-assistant-cli";
    changelog = "https://github.com/home-assistant-ecosystem/home-assistant-cli/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.asl20;
    teams = [ lib.teams.home-assistant ];
  };
})
