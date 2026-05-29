# 3D model drop point

Drop a Galaxy Buds 3 FE model here named exactly:

    buds3fe.usdz

`BudsModel3DView` looks for it at launch and renders it (with auto-spin and
drag-to-rotate). If it's missing, the view falls back to a procedural chrome
earbud built in code, so the app always shows *something* in 3D.

Sourcing notes:
- No official Samsung USDZ exists — model it in Blender and export USDZ, or
  find a permissively/CC-licensed earbud model on Sketchfab.
- For the public OSS repo, ship a self-made or properly-licensed model only;
  Samsung's renders/models are copyrighted.
