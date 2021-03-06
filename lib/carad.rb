class CarAd < ActiveRecord::Base

require 'open-uri'

  define_singleton_method(:scrape) do
    rightnow = Time.new
    olderads = false

    #cycle through the first however many pages of craigslist, breaking out of this loop if we find that our ads are old or redundant.
    (1..100).each do |i|
      doc = Nokogiri::HTML(open("http://portland.craigslist.org/search/cto?s=#{i}00&"))
      content = doc.xpath("//div[contains(@class,'content')]")
      posts = content.xpath("//span[contains(@class,'txt')]")

      #parse out each individual post
      posts.each() do |post|
        if post.xpath("span").inner_text.index(/\$\d+/) != nil
          post_date = Time.parse(post.xpath("span/time/@datetime").text)
          clid = post.xpath("span/a/@data-id").text

          #breakout of the main paging loop if we find that our postings are either older than 24 hours or already in the db, by craigslist id.
          if (rightnow - post_date) > 86400
            olderads = true
            break
          # elsif CarAd.find(:clid => clid).count >= 1
          #   olderads = true
          #   break
          end

          price = post.xpath("span").inner_text.slice!(/\$\d+/).slice!(/\d+/).to_i()
          if price > 100 && price < 3000000
            description = post.xpath("span/a").inner_text
            city = post.xpath("span").inner_text.slice!(/\([a-zA-Z]+\)/)

            CarAd.create(:price => price, :city => city, :description => description, :date => post_date, :clid => clid)
          end
        end
      end
      if olderads == true
        break
      end
    end
  end
end
