final: prev: {
  vscode-extensions = prev.vscode-extensions // {
    mashurr = (prev.vscode-extensions.mashurr or { }) // {
      git-pinned-commit-highlighter = final.vscode-utils.buildVscodeMarketplaceExtension {
        # Make sure this patch is aligned with the pinned version
        mktplcRef = {
          publisher = "mashurr";
          name = "git-pinned-commit-highlighter";
          version = "0.1.0";
          hash = "sha256-ML6mIQ/1L6Jn7t6I3/G64j1euEUzeW+Z8ETmnpCgJ/A=";
        };

        postPatch = ''
          explorer_registration=$(cat <<'JS'
              let shown;
              const fileDecorations = new Map();
              const decorationChanges = new vscode.EventEmitter();
              const decorationProvider = vscode.window.registerFileDecorationProvider({
                  onDidChangeFileDecorations: decorationChanges.event,
                  provideFileDecoration: (uri) => fileDecorations.get(uri.toString()),
              });
          JS
          )

          explorer_refresh=$(cat <<'JS'
                          .sort((a, b) => a.resourceUri.fsPath.localeCompare(b.resourceUri.fsPath));
                      const affectedUris = new Map([...fileDecorations.keys()].map((key) => [key, vscode.Uri.parse(key)]));
                      fileDecorations.clear();
                      for (const resource of changes.resourceStates) {
                          const key = resource.resourceUri.toString();
                          affectedUris.set(key, resource.resourceUri);
                          fileDecorations.set(key, {
                              badge: 'P',
                              tooltip: `Pinned: ''${resource.decorations.tooltip}`,
                              color: resource.decorations.iconPath.color,
                              propagate: true,
                          });
                      }
                      // Explicit file events also update collapsed parent folders and clear reverted files
                      decorationChanges.fire([...affectedUris.values()]);
          JS
          )

          substituteInPlace out/extension.js \
            --replace-fail '    let shown;' "$explorer_registration" \
            --replace-fail \
              '                .sort((a, b) => a.resourceUri.fsPath.localeCompare(b.resourceUri.fsPath));' \
              "$explorer_refresh" \
            --replace-fail \
              '    const listeners = watched.map((r) => r.state.onDidChange(update));' \
              '    const listeners = [decorationProvider, decorationChanges, ...watched.map((r) => r.state.onDidChange(update))];'
        '';
      };
    };
  };
}
