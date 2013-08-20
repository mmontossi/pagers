module Pageable
  module ActiveRecord
    module Relation
      extend ActiveSupport::Concern

      def per(value)
        value = [value.to_i, 1].max
        limit(value).offset(value * (offset_value / limit_value))
      end      
      
      def padding(value)
        @padding = value
        r = (offset_value + value) < 0 ? self : offset(offset_value + value)
        decrease_limit? ? r.limit(limit_value + value) : r
      end
      
      def total_count
        @total_count ||= begin
          r = except(:offset, :limit, :order, :reorder)
          r = r.except(:includes) unless eager_loading?
          r = r.count
          r.respond_to?(:count) ? r.count : r
        end
      end            
      
      def total_pages
        @total_pages ||= [(fixed_total_count.to_f / fixed_limit_value).ceil, 1].max
      end

      def current_page
        @current_page ||= (offset_value.to_f / fixed_limit_value).ceil + 1
      end

      def previous_page
        @previous_page ||= current_page > 1 ? (current_page - 1) : nil
      end
      
      def next_page
        @next_page ||= current_page < total_pages ? (current_page + 1) : nil
      end
      
      def first_page
        1
      end
      
      def last_page
        total_pages
      end      
      
      def out_of_bounds?
        @out_of_bounds ||= current_page > total_pages or current_page < first_page
      end
      
      protected
      
      def has_padding?
        !defined?(@padding).nil?
      end
      
      def padding_negative?
        has_padding? and @padding < 0
      end
      
      def decrease_limit?
        padding_negative? and offset_value == 0
      end
      
      def fixed_total_count
        total_count - (padding_negative? ? @padding : 0)
      end
      
      def fixed_limit_value
        limit_value - (decrease_limit? ? @padding : 0)
      end

    end
  end
end