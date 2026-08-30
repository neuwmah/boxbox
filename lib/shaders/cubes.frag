#version 460 core

#include <flutter/runtime_effect.glsl>

out vec4 fragColor;

uniform vec4 uViewport;
uniform vec4 uCamera;
uniform vec4 uRight;
uniform vec4 uUp;
uniform vec4 uForward;
uniform vec4 uTint;
uniform sampler2D uGrid;

const float kExtent = 18.0;
const float kGrid = 37.0;
const float kHalf = 0.5;
const float kSlab = 1.5;
const float kFogNear = 22.0;
const float kFogFar = 40.0;
const float kAmbient = 0.055;
const float kSpecular = 0.08;
const float kShininess = 30.0;
const float kReach = 8.5;
const float kLightMin = -15.0;
const float kLightStep = 5.0;
const float kLightY = 2.0;
const int kMaxSteps = 64;

float cellHeight(vec2 cell, out float colored) {
    vec4 g = texture(uGrid, (cell + kExtent + 0.5) / kGrid);
    colored = g.b;
    return sin(uCamera.w * 0.01 + g.g * 4.0) * g.r;
}

vec3 shadePoint(vec3 p, vec3 n, vec3 albedo, float keep) {
    vec3 view = normalize(uCamera.xyz - p);
    float lit = kAmbient;

    int i0 = int(ceil((p.x - kReach - kLightMin) / kLightStep));
    int j0 = int(ceil((p.z - kReach - kLightMin) / kLightStep));

    for (int a = 0; a < 4; a++) {
        int i = i0 + a;
        if (i < 0 || i > 6) continue;
        float lightX = kLightMin + float(i) * kLightStep;
        for (int b = 0; b < 4; b++) {
            int j = j0 + b;
            if (j < 0 || j > 6) continue;
            vec3 toLight =
                vec3(lightX, kLightY, kLightMin + float(j) * kLightStep) - p;
            float d2 = dot(toLight, toLight);
            if (d2 > kReach * kReach || d2 < 1e-6) continue;
            float d = sqrt(d2);
            vec3 l = toLight / d;
            float ndotl = dot(n, l);
            if (ndotl <= 0.0) continue;
            float atten = 1.0 - d / kReach;
            lit += ndotl * atten;
            float rdotv = max(dot(n * (2.0 * ndotl) - l, view), 0.0);
            lit += pow(rdotv, kShininess) * atten * kSpecular;
        }
    }
    return albedo * (lit * keep);
}

void main() {
    fragColor = vec4(0.0);

    vec2 size = uViewport.xy;
    float focal = uViewport.z;
    float aspect = uViewport.w;
    vec3 cam = uCamera.xyz;
    float plainAlbedo = uRight.w;

    vec2 frag = FlutterFragCoord().xy;
    float ndcX = frag.x / size.x * 2.0 - 1.0;
    float ndcY = 1.0 - frag.y / size.y * 2.0;
    vec3 rd = normalize(
        uForward.xyz +
        uRight.xyz * (ndcX * aspect / focal) +
        uUp.xyz * (ndcY / focal)
    );

    if (rd.y > -1e-4) return;

    float tEnter = max((kSlab - cam.y) / rd.y, 0.0);
    float span = min((-kSlab - cam.y) / rd.y, kFogFar) - tEnter;
    if (span <= 0.0) return;

    vec3 ro = cam + rd * tEnter;
    vec3 safeRd = vec3(
        abs(rd.x) < 1e-6 ? 1e-6 : rd.x,
        rd.y,
        abs(rd.z) < 1e-6 ? 1e-6 : rd.z
    );

    vec2 cell = floor(ro.xz + kHalf);
    vec2 stp = vec2(rd.x >= 0.0 ? 1.0 : -1.0, rd.z >= 0.0 ? 1.0 : -1.0);
    vec2 deltaDist = abs(1.0 / safeRd.xz);
    vec2 sideDist = (cell + stp * kHalf - ro.xz) / safeRd.xz;

    for (int s = 0; s < kMaxSteps; s++) {
        if (abs(cell.x) <= kExtent && abs(cell.y) <= kExtent) {
            float colored;
            float cy = cellHeight(cell, colored);
            vec3 center = vec3(cell.x, cy, cell.y);
            vec3 lo = (center - vec3(kHalf) - ro) / safeRd;
            vec3 hi = (center + vec3(kHalf) - ro) / safeRd;
            vec3 tlo = min(lo, hi);
            vec3 thi = max(lo, hi);
            float tmin = max(max(tlo.x, tlo.y), tlo.z);
            float tmax = min(min(thi.x, thi.y), thi.z);

            if (tmax >= max(tmin, 0.0) && tmin <= span) {
                vec3 n = vec3(0.0);
                if (tlo.x >= tlo.y && tlo.x >= tlo.z) {
                    n.x = -sign(safeRd.x);
                } else if (tlo.y >= tlo.z) {
                    n.y = -sign(safeRd.y);
                } else {
                    n.z = -sign(safeRd.z);
                }

                float fogT = clamp(
                    (distance(cam, center) - kFogNear) / (kFogFar - kFogNear),
                    0.0,
                    1.0
                );
                float keep = 1.0 - fogT * fogT * (3.0 - 2.0 * fogT);
                vec3 albedo = colored > 0.5 ? uTint.xyz : vec3(plainAlbedo);
                vec3 hit = ro + rd * max(tmin, 0.0);
                fragColor = vec4(
                    clamp(shadePoint(hit, n, albedo, keep), 0.0, 1.0),
                    1.0
                );
                return;
            }
        }

        float t;
        if (sideDist.x < sideDist.y) {
            t = sideDist.x;
            sideDist.x += deltaDist.x;
            cell.x += stp.x;
        } else {
            t = sideDist.y;
            sideDist.y += deltaDist.y;
            cell.y += stp.y;
        }
        if (t > span) return;
    }
}
