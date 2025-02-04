{ symlinkJoin
, lib
, makeWrapper
, nemo
, nemoExtensions
, extensions ? [ ]
, useDefaultExtensions ? true
}:

let
  selectedExtensions = extensions ++ (lib.optionals useDefaultExtensions nemoExtensions);
in
symlinkJoin {
  name = "nemo-with-extensions-${nemo.version}";

  paths = [ nemo ] ++ selectedExtensions;

  nativeBuildInputs = [ makeWrapper ];

  postBuild = ''
    for f in $(find $out/bin/ $out/libexec/ -type l -not -path "*/.*"); do
      wrapProgram "$f" \
        --set "NEMO_EXTENSION_DIR" "$out/${nemo.extensiondir}" \
        --set "NEMO_PYTHON_EXTENSION_DIR" "$out/share/nemo-python/extensions"
    done

    # Point to wrapped binary in all service files
    for file in "share/dbus-1/services/nemo.FileManager1.service" \
      "share/dbus-1/services/nemo.service"
    do
      rm "$out/$file"
      substitute "${nemo}/$file" "$out/$file" \
        --replace "${nemo}" "$out"
    done
  '';

  inherit (nemo) meta;
}
