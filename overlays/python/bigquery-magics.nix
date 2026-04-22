final: prev:
let
  inherit (final) fetchFromGitHub lib;
in
{
  pythonPackagesExtensions = (prev.pythonPackagesExtensions or [ ]) ++ [
    (pythonFinal: pythonPrev: {
      bigquery-magics = pythonFinal.buildPythonPackage rec {
        pname = "bigquery-magics";
        version = "0.14.0";
        format = "setuptools";
        disabled = pythonFinal.pythonOlder "3.10";

        src = fetchFromGitHub {
          owner = "googleapis";
          repo = "google-cloud-python";
          rev = "bigquery-magics-v${version}";
          hash = "sha256-OjncCE9RQuTO8PZbZNZBMap5Batn8OwNnKp1QYobqAQ=";
        };
        sourceRoot = "source/packages/bigquery-magics";

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
          pyopenssl
          tqdm
        ];

        pythonImportsCheck = [ "bigquery_magics" ];
        doCheck = false;

        meta = with lib; {
          description = "IPython Magics for BigQuery";
          homepage = "https://github.com/googleapis/google-cloud-python/tree/main/packages/bigquery-magics";
          license = licenses.asl20;
        };
      };
    })
  ];
}
