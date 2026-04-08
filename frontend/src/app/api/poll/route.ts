const API_BACKEND = process.env.API_BACKEND_URL || "http://vibecheck-api.vibecheck.svc.cluster.local:5001";

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const res = await fetch(`${API_BACKEND}/poll`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
    const data = await res.json();
    return Response.json(data, { status: res.status });
  } catch {
    return Response.json({ error: "API unavailable" }, { status: 502 });
  }
}
