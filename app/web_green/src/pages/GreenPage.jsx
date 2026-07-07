import { useEffect, useState } from "react";
import { getApiBaseUrl } from "../lib/api";

export default function GreenPage() {
  const [message, setMessage] = useState("WAS green 응답을 확인하는 중입니다...");
  const [status, setStatus] = useState("loading");

  useEffect(() => {
    document.title = "K-Glow Beauty | Green";

    fetch(`${getApiBaseUrl()}/api/green`, { credentials: "include" })
      .then(async (response) => {
        const text = await response.text();
        if (!response.ok) {
          throw new Error(text || `${response.status} ${response.statusText}`);
        }
        setMessage(text);
        setStatus("success");
      })
      .catch((error) => {
        console.warn("Green WAS 테스트 API 호출 실패", error);
        setMessage("WAS green /api/green 호출에 실패했습니다.");
        setStatus("error");
      });
  }, []);

  return (
    <main className="form-shell">
      <h1>green</h1>
      <p className="muted">Green 배포 확인용 페이지입니다.</p>
      <div className={`form-message ${status === "success" ? "success" : status === "error" ? "error" : ""}`}>
        {message}
      </div>
    </main>
  );
}
