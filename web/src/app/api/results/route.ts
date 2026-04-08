const API_BACKEND = process.env.API_BACKEND_URL || "http://vibecheck-api:5001";

export async function GET() {
  const res = await fetch(`${API_BACKEND}/results`, { cache: "no-store" });
  const data = await res.json();
  return Response.json(data);
}
