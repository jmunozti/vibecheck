"use client";

import { useEffect, useState, useCallback, useMemo } from "react";
import { Card, CardContent, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { ChartConfig, ChartContainer, ChartTooltip, ChartTooltipContent } from "@/components/ui/chart";
import { Label, LabelList, Pie, PieChart } from "recharts";

interface PollOptions {
  a: string;
  b: string;
}

interface PollResults {
  a: number;
  b: number;
}

const API_URL = process.env.NEXT_PUBLIC_API_URL || "";

export function PollCard() {
  const [options, setOptions] = useState<PollOptions>({ a: "Obviously", b: "Crime" });
  const [results, setResults] = useState<PollResults>({ a: 0, b: 0 });
  const [userChoice, setUserChoice] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const total = results.a + results.b;

  const AMBER = "#f59e0b";
  const RED = "#ef4444";

  const chartData = useMemo(
    () => [
      { option: options.a, votes: total > 0 ? results.a : 1, fill: AMBER },
      { option: options.b, votes: total > 0 ? results.b : 1, fill: RED },
    ],
    [options, results, total]
  );

  const chartConfig = useMemo(
    () =>
      ({
        votes: { label: "Votes" },
        [options.a]: { label: options.a, color: AMBER },
        [options.b]: { label: options.b, color: RED },
      }) satisfies ChartConfig,
    [options]
  );

  const fetchResults = useCallback(async () => {
    try {
      const res = await fetch(`${API_URL}/api/results`);
      if (res.ok) {
        const data = await res.json();
        setResults({ a: data.a || 0, b: data.b || 0 });
        setError(null);
      }
    } catch {
      setError("Cannot connect to API");
    }
  }, []);

  useEffect(() => {
    fetch(`${API_URL}/api/info`)
      .then((r) => r.json())
      .then((data) => {
        if (data.options) setOptions(data.options);
      })
      .catch(() => {});

    fetchResults();
    const interval = setInterval(fetchResults, 2000);
    return () => clearInterval(interval);
  }, [fetchResults]);

  async function submitPoll(choice: string) {
    if (isSubmitting) return;
    setIsSubmitting(true);

    try {
      const res = await fetch(`${API_URL}/api/poll`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ choice }),
      });

      if (res.ok) {
        setUserChoice(choice);
        await fetchResults();
      }
    } catch {
      setError("Failed to submit");
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <Card className="w-[420px] border-amber-200 bg-white/90 backdrop-blur-sm shadow-xl rounded-2xl">
      <CardHeader className="text-center pb-2">
        <div className="text-5xl mb-2">🍕</div>
        <CardTitle className="text-3xl font-bold text-zinc-900" style={{ fontFamily: "var(--font-fredoka)" }}>
          Pineapple on Pizza?
        </CardTitle>
        <p className="text-sm text-amber-700 font-medium">The internet&apos;s most divisive debate</p>
      </CardHeader>
      <CardContent className="space-y-6">
        {error && (
          <div className="rounded-md bg-red-50 border border-red-200 p-3 text-center text-sm text-red-600">
            {error}
          </div>
        )}

        <div className="grid grid-cols-2 gap-3">
          <Button
            variant={userChoice === "a" ? "default" : "outline"}
            size="lg"
            className={`group h-18 text-lg cursor-pointer rounded-xl font-semibold transition-all duration-300 hover:scale-105 hover:shadow-lg active:scale-95 ${userChoice === "a" ? "bg-amber-500 hover:bg-amber-600 text-white shadow-amber-300/50" : "border-amber-300 text-amber-900 hover:bg-amber-50"}`}
            style={{ fontFamily: "var(--font-fredoka)" }}
            onClick={() => submitPoll("a")}
            disabled={isSubmitting}
          >
            <span className="inline-block transition-transform duration-300 group-hover:rotate-12 group-hover:scale-125">🍍</span>
            <span className="transition-all duration-300 group-hover:tracking-wider">{options.a}</span>
            {userChoice === "a" && <span className="animate-bounce inline-block ml-1">✓</span>}
          </Button>
          <Button
            variant={userChoice === "b" ? "default" : "outline"}
            size="lg"
            className={`group h-18 text-lg cursor-pointer rounded-xl font-semibold transition-all duration-300 hover:scale-105 hover:shadow-lg active:scale-95 ${userChoice === "b" ? "bg-red-500 hover:bg-red-600 text-white shadow-red-300/50" : "border-red-300 text-red-900 hover:bg-red-50"}`}
            style={{ fontFamily: "var(--font-fredoka)" }}
            onClick={() => submitPoll("b")}
            disabled={isSubmitting}
          >
            <span className="inline-block transition-transform duration-300 group-hover:rotate-12 group-hover:scale-125">🚫</span>
            <span className="transition-all duration-300 group-hover:tracking-wider">{options.b}</span>
            {userChoice === "b" && <span className="animate-bounce inline-block ml-1">✓</span>}
          </Button>
        </div>

        <div className="h-[250px]">
          <ChartContainer config={chartConfig} className="mx-auto aspect-square h-full [&_.recharts-sector[stroke='#fff']]:!stroke-white [&_.recharts-sector]:!outline-none">
            <PieChart>
              <ChartTooltip content={<ChartTooltipContent nameKey="option" hideLabel />} />
              <Pie data={chartData} dataKey="votes" nameKey="option" stroke="#ffffff" strokeWidth={3}>
                <LabelList
                  dataKey="option"
                  fill="#fff"
                  stroke="none"
                  fontSize={14}
                  fontWeight={700}
                  formatter={(value) => {
                    const str = String(value ?? "");
                    if (total === 0) return str;
                    const item = chartData.find((d) => d.option === str);
                    if (!item) return str;
                    const pct = Math.round((item.votes / total) * 100);
                    return `${str} ${pct}%`;
                  }}
                />
              </Pie>
            </PieChart>
          </ChartContainer>
        </div>

        <p className="text-center text-sm text-zinc-500" style={{ fontFamily: "var(--font-fredoka)" }}>
          {total === 0 ? "No votes yet — be the first!" : `${total} vote${total !== 1 ? "s" : ""}`}
        </p>
      </CardContent>
      <CardFooter className="flex justify-center">
        <div className="flex gap-6 text-sm text-zinc-700" style={{ fontFamily: "var(--font-fredoka)" }}>
          <div className="flex items-center gap-2">
            <div className="h-3 w-3 rounded-full" style={{ backgroundColor: AMBER }} />
            <span>{options.a}</span>
            <Badge variant="secondary">{results.a}</Badge>
          </div>
          <div className="flex items-center gap-2">
            <div className="h-3 w-3 rounded-full" style={{ backgroundColor: RED }} />
            <span>{options.b}</span>
            <Badge variant="secondary">{results.b}</Badge>
          </div>
        </div>
      </CardFooter>
    </Card>
  );
}
