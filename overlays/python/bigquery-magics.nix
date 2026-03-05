final: prev:
let
  inherit (final) fetchFromGitHub lib;
in
{
  pythonPackagesExtensions = (prev.pythonPackagesExtensions or [ ]) ++ [
    (pythonFinal: pythonPrev: {
      bigquery-magics = pythonFinal.buildPythonPackage rec {
        pname = "bigquery-magics";
        version = "0.12.1";
        format = "setuptools";

        src = fetchFromGitHub {
          owner = "googleapis";
          repo = "python-bigquery-magics";
          rev = "v${version}";
          hash = "sha256-iGGLivWAQkGIOh7ElCVxq07POwVNOqdqCiP41sSnZuo=";
        };

        propagatedBuildInputs = with pythonPrev; [
          db-dtypes
          google-cloud-bigquery
          ipykernel
          ipython
          ipywidgets
          packaging
          pandas
          pyarrow
          pydata-google-auth
          tqdm
        ];

        pythonImportsCheck = [ "bigquery_magics" ];
        doCheck = false;

        meta = with lib; {
          description = "IPython Magics for BigQuery";
          homepage = "https://github.com/googleapis/python-bigquery-magics";
          license = licenses.asl20;
        };
      };
    })
  ];
}
