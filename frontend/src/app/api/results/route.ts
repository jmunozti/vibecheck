const API_BACKEND = process.env.API_BACKEND_URL || "http://vibecheck-api.vibecheck.svc.cluster.local:5001";

export async function GET() {
  try {
    const res = await fetch(`${API_BACKEND}/results`, { cache: "no-store" });
    const data = await res.json();
    return Response.json(data);
  } catch {
    return Response.json({ error: "API unavailable" }, { status: 502 });
  }
}
