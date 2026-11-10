# Makes a tiny stand-in for water-polygons-split-3857.zip (the world's sea coastlines), for
# servers that can't reach osmdata.openstreetmap.de. Sokoto has no sea, so the map is the same.
# One small square of "sea" at 0,0 (Gulf of Guinea), outside the area we build.
import struct, zipfile, sys
out = sys.argv[1] if len(sys.argv) > 1 else "data/sources/water-polygons-split-3857.zip"
pts = [(0.0, 0.0), (0.0, 1000.0), (1000.0, 1000.0), (1000.0, 0.0), (0.0, 0.0)]  # clockwise = outer ring
box = (0.0, 0.0, 1000.0, 1000.0)
content = struct.pack("<i4d2i", 5, *box, 1, len(pts)) + struct.pack("<i", 0) + b"".join(struct.pack("<2d", *p) for p in pts)
def header(total_bytes):
    return struct.pack(">7i", 9994, 0, 0, 0, 0, 0, total_bytes // 2) + struct.pack("<2i", 1000, 5) + struct.pack("<8d", *box, 0, 0, 0, 0)
shp = header(100 + 8 + len(content)) + struct.pack(">2i", 1, len(content) // 2) + content
shx = header(100 + 8) + struct.pack(">2i", 50, len(content) // 2)
field = b"FID".ljust(11, b"\0") + b"N" + b"\0" * 4 + bytes([9, 0]) + b"\0" * 14
dbf = struct.pack("<B3BIHH20x", 3, 126, 11, 8, 1, 32 + 32 + 1, 1 + 9) + field + b"\r" + b" " + b"0".rjust(9) + b"\x1a"
prj = ('PROJCS["WGS_1984_Web_Mercator_Auxiliary_Sphere",GEOGCS["GCS_WGS_1984",DATUM["D_WGS_1984",SPHEROID["WGS_1984",6378137.0,298.257223563]],'
       'PRIMEM["Greenwich",0.0],UNIT["Degree",0.0174532925199433]],PROJECTION["Mercator_Auxiliary_Sphere"],PARAMETER["False_Easting",0.0],'
       'PARAMETER["False_Northing",0.0],PARAMETER["Central_Meridian",0.0],PARAMETER["Standard_Parallel_1",0.0],PARAMETER["Auxiliary_Sphere_Type",0.0],UNIT["Meter",1.0]]')
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    d = "water-polygons-split-3857/water_polygons"
    z.writestr(d + ".shp", shp); z.writestr(d + ".shx", shx); z.writestr(d + ".dbf", dbf); z.writestr(d + ".prj", prj); z.writestr(d + ".cpg", "UTF-8")
print("made", out)
