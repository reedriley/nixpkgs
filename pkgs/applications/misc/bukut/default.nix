{ lib, python3, fetchFromGitHub }:

with python3.pkgs; buildPythonApplication rec {
  pname = "bukut";
  version = "0.11";

  src = fetchFromGitHub {
    owner = "peterjschroeder";
    repo = "bukut";
    rev = "v${version}";
    sha256 = "sha256-MCAyMvzXnC7QSpWeG7qorK4JmRBMzG3eGsp5YpKmVjg=";
  };

  propagatedBuildInputs = [
    asciimatics
    beautifulsoup4
    natsort
    pyperclip
    pyxdg
  ];

  meta = with lib; {
    description = "Text user interface for buku bookmark manager";
    homepage = "https://github.com/peterjschroeder/bukut";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ taha ];
  };
}
