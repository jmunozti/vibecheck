import { PollCard } from "@/components/poll-card";

export default function Home() {
  return (
    <main className="relative flex min-h-screen items-center justify-center p-4 overflow-hidden">
      {/* Pizza background image from Unsplash (free for commercial use) */}
      <div
        className="absolute inset-0 bg-cover bg-center"
        style={{
          backgroundImage: "url('https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=1920&q=80')",
        }}
      />
      {/* Dark overlay for readability */}
      <div className="absolute inset-0 bg-black/40" />
      <div className="relative z-10">
        <PollCard />
      </div>
    </main>
  );
}
