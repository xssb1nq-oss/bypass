import asyncio
import httpx
from aiogram import Bot, Dispatcher, types
from aiogram.filters import Command

BOT_TOKEN = "YOUR_TOKEN"

# Приоритет: сначала bypass.vip, fallback на bypass.city
BYPASS_APIS = [
    "https://bypass.vip/v2",
    "https://api.bypass.city/v2",
]

SUPPORTED_DOMAINS = [
    "linkvertise", "lootlabs", "link-center", "sub2unlock",
    "sub2get", "shortlinks.gg", "social-unlock", "boost.ink",
    "exe.io", "gplinks", "shrinkme", "ouo.io", "fc.lc",
    "bc.vc", "adfoc.us", "link1s", "za.gl", "jo.vc",
    "ay.link", "link-to", "linkpays", "losshaste",
]

bot = Bot(token=BOT_TOKEN)
dp = Dispatcher()

def is_supported(url: str) -> bool:
    return any(d in url for d in SUPPORTED_DOMAINS)

async def try_bypass(url: str) -> str | None:
    async with httpx.AsyncClient(timeout=30) as client:
        for api in BYPASS_APIS:
            try:
                r = await client.get(api, params={"url": url})
                if r.status_code != 200:
                    continue
                data = r.json()
                # разные API разные поля
                result = (
                    data.get("destination")
                    or data.get("result")
                    or data.get("bypassed")
                    or data.get("url")
                )
                if result and result != url:
                    return result
            except Exception:
                continue
    return None

async def follow_redirects(url: str) -> str:
    """Fallback — просто проследить редиректы"""
    try:
        async with httpx.AsyncClient(
            follow_redirects=True,
            timeout=15,
            headers={"User-Agent": "Mozilla/5.0"}
        ) as client:
            r = await client.get(url)
            return str(r.url)
    except Exception:
        return url

@dp.message(Command("start"))
async def start(message: types.Message):
    await message.answer(
        "Кидай ссылку — обойду.\n"
        "Поддерживаю: linkvertise, lootlabs, sub2unlock, gplinks и ещё 50+"
    )

@dp.message()
async def handle(message: types.Message):
    text = message.text.strip()

    # вытащить все ссылки из сообщения
    urls = [w for w in text.split() if w.startswith("http")]

    if not urls:
        return

    for url in urls:
        status_msg = await message.answer(f"⏳ Обрабатываю...")

        if is_supported(url):
            result = await try_bypass(url)
            if result:
                await status_msg.edit_text(f"✅ {result}")
            else:
                # bypass не сработал — попробуем редиректы
                fallback = await follow_redirects(url)
                if fallback != url:
                    await status_msg.edit_text(f"↪️ {fallback}")
                else:
                    await status_msg.edit_text("❌ Не удалось обойти")
        else:
            # неизвестный сервис — всё равно пробуем
            result = await try_bypass(url)
            if not result:
                result = await follow_redirects(url)
            await status_msg.edit_text(f"↪️ {result}")

async def main():
    await dp.start_polling(bot)

if __name__ == "__main__":
    asyncio.run(main())
