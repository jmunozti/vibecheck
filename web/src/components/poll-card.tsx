"use client";

import { useEffect, useState, useCallback } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Progress } from "@/components/ui/progress";
import { Badge } from "@/components/ui/badge";

interface PollOptions {
  a: string;
  b: string;
}

interface PollResults {
  a: number;
  b: number;
}

const API_URL = process.env.NEXT_PUBLIC_API_URL || "";

function getUserId(): string {
  if (typeof window === "undefined") return "";
  let id = localStorage.getItem("vibecheck_user_id");
  if (!id) {
    id = Math.random().toString(36).slice(2) + Date.now().toString(36);
    localStorage.setItem("vibecheck_user_id", id);
  }
  return id;
}

export function PollCard() {
  const [options, setOptions] = useState<PollOptions>({ a: "Obviously", b: "Crime" });
  const [results, setResults] = useState<PollResults>({ a: 0, b: 0 });
  const [userChoice, setUserChoice] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const total = results.a + results.b;
  const pctA = total > 0 ? Math.round((results.a / total) * 100) : 50;
  const pctB = total > 0 ? 100 - pctA : 50;

  const fetchResults = useCallback(async () => {
    try {
      const res = await fetch(`${API_URL}/results`);
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
    fetch(`${API_URL}/`)
      .then((r) => r.json())
      .then((data) => {
        if (data.options) setOptions(data.options);
      })
      .catch(() => {});

    const saved = localStorage.getItem("vibecheck_choice");
    if (saved) setUserChoice(saved);

    fetchResults();
    const interval = setInterval(fetchResults, 2000);
    return () => clearInterval(interval);
  }, [fetchResults]);

  async function submitPoll(choice: string) {
    if (isSubmitting) return;
    setIsSubmitting(true);

    try {
      const res = await fetch(`${API_URL}/poll`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ choice, user_id: getUserId() }),
      });

      if (res.ok) {
        setUserChoice(choice);
        localStorage.setItem("vibecheck_choice", choice);
        await fetchResults();
      }
    } catch {
      setError("Failed to submit");
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <Card className="w-full max-w-md border-zinc-800 bg-zinc-900">
      <CardHeader className="text-center">
        <CardTitle className="text-2xl font-bold">Pineapple on Pizza?</CardTitle>
        <p className="text-sm text-zinc-400">The internet&apos;s most divisive debate</p>
      </CardHeader>
      <CardContent className="space-y-6">
        {error && (
          <div className="rounded-md bg-red-950/50 border border-red-800 p-3 text-center text-sm text-red-400">
            {error}
          </div>
        )}

        <div className="grid grid-cols-2 gap-3">
          <Button
            variant={userChoice === "a" ? "default" : "outline"}
            size="lg"
            className="h-16 text-lg"
            onClick={() => submitPoll("a")}
            disabled={isSubmitting}
          >
            {options.a}
            {userChoice === "a" && " ✓"}
          </Button>
          <Button
            variant={userChoice === "b" ? "default" : "outline"}
            size="lg"
            className="h-16 text-lg"
            onClick={() => submitPoll("b")}
            disabled={isSubmitting}
          >
            {options.b}
            {userChoice === "b" && " ✓"}
          </Button>
        </div>

        <div className="space-y-3">
          <div className="flex items-center justify-between text-sm">
            <span>{options.a}</span>
            <Badge variant="secondary">{pctA}%</Badge>
          </div>
          <Progress value={pctA} className="h-3" />

          <div className="flex items-center justify-between text-sm">
            <span>{options.b}</span>
            <Badge variant="secondary">{pctB}%</Badge>
          </div>
          <Progress value={pctB} className="h-3" />
        </div>

        <p className="text-center text-sm text-zinc-500">
          {total === 0
            ? "No votes yet"
            : `${total} vote${total !== 1 ? "s" : ""}`}
        </p>
      </CardContent>
    </Card>
  );
}
