module PostSetPresenters
  class Post < Base
    attr_accessor :post_set, :tag_set_presenter
    delegate :posts, :to => :post_set

    def initialize(post_set)
      @post_set = post_set
      @tag_set_presenter = TagSetPresenter.new(related_tags)
    end

    def related_tags
      if post_set.is_pattern_search?
        pattern_tags
      elsif post_set.is_tag_subscription?
        post_set.tag_subscription_tags
      elsif post_set.is_single_tag?
        related_tags_for_single(post_set.tag_string)
      elsif post_set.unordered_tag_array.size == 1
        related_tags_for_single(post_set.unordered_tag_array.first)
      elsif post_set.tag_string =~ /(?:^|\s)(?:#{Tag::SUBQUERY_METATAGS}):\S+/
        calculate_related_tags_from_post_set
      elsif post_set.is_empty_tag?
        popular_tags
      else
        related_tags_for_group
      end
    end

    def popular_tags
      Tag.trending
    end

    def pattern_tags
      Tag.name_matches(post_set.tag_string).all(:select => "name", :limit => Danbooru.config.tag_query_limit, :order => "post_count DESC").map(&:name)
    end

    def related_tags_for_group
      RelatedTagCalculator.calculate_from_sample_to_array(post_set.tag_string).map(&:first)
    end

    def related_tags_for_single(tag_string)
      tag = Tag.find_by_name(tag_string.downcase)

      if tag
        tag.related_tag_array.map(&:first)
      else
        calculate_related_tags_from_post_set
      end
    end

    def calculate_related_tags_from_post_set
      RelatedTagCalculator.calculate_from_post_set_to_array(post_set).map(&:first)
    end

    def tag_list_html(template, options = {})
      tag_set_presenter.tag_list_html(template, options)
    end
  end
end
