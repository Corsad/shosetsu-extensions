local baseURL = "https://bcatranslation.com"

local encode = Require("url").encode

local text = function(v)
  return v:text()
end


local function shrinkURL(url)
  return url:gsub("^.-bcatranslation%.com", "")
end

local function expandURL(url)
  return baseURL .. url
end

local function parseListing(url)
  local doc = GETDocument(expandURL(url))
  local data = doc:selectFirst("#primary-menu .menu-item:nth-child(3) .sub-menu")
  return mapNotNil(data:select("li"), function(v)
    local a = v:selectFirst("a")
    if a ~= nil then
      return Novel {
        title = a:text(),
        link = shrinkURL(a:attr("href")),
      }
    end
  end)
end

local function getChapterList(content, novelURL)
  local chapterList = content:selectFirst(".entry-content"):select("p")
  local chapters = (mapNotNil(chapterList, function(v, i)
    local a = v:selectFirst("a")
    if a ~= nil and string.find(a:attr("href"), "chapter") then
      return NovelChapter {
        order = i,
        title = a:text(),
        link = shrinkURL(a:attr("href")),
      }
    end
  end))
  return chapters
end

local function parseNovel(novelURL, loadChapters)
  local doc = GETDocument(expandURL(novelURL))
  local content = doc:selectFirst("#primary")
  local description = topSection:selectFirst(".elementor-section:nth-last-child(1)"):selectFirst(".elementor-widget-container")
  local info = NovelInfo {
    title = content:selectFirst(".entry-title"):text()
  }
  
  if loadChapters then
    local chapters = {}
    chapters[#chapters+1] = getChapterList(content)
    local chapterList = AsList(flatten(chapters))
    info:setChapters(chapterList)
  end
  return info
end

local function getPassage(chapterURL)
  local doc = GETDocument(expandURL(chapterURL))
  local title = nil
  local chap = doc:selectFirst(".elementor-section.elementor-top-section:nth-child(2) .elementor-widget-container")
  if title == nil then
    title = chap:selectFirst("p")
  end
  title = title:text()
  chap:select("div"):remove()
  chap:selectFirst("p"):remove()
  chap:child(0):before("<h1>" .. title .. "</h1>")
  return pageOfElem(chap, true)
end

local function getNovelsListing(data) 
  return parseListing("/")
end

local function getSearch(data)
  local url = "/"
  return parseListing(url)
end

return {
  id = 4305,
  name = "bcatranslation",
  baseURL = baseURL,
  chapterType = ChapterType.HTML,

  listings = {
    Listing("All Novels", true, getNovelsListing)
  },
  getPassage = getPassage,
  parseNovel = parseNovel,
  
  -- Website has intentially broken their search function (Thus Disabled)
  hasSearch = false,
  isSearchIncrementing = true,
  search = getSearch,

  shrinkURL = shrinkURL,
  expandURL = expandURL
}
